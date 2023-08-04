// Copyright © 2020 Metabolist. All rights reserved.

import AppUrls
import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public enum Navigation {
    case url(URL)
    case collection(CollectionService)
    case profile(ProfileService)
    case notification(NotificationService)
    case searchScope(SearchScope)
    case webfingerStart
    case webfingerEnd
    case authenticatedWebView(AuthenticatedWebViewService, URL)
}

public struct NavigationService {
    private let environment: AppEnvironment
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    public init(
        environment: AppEnvironment,
        mastodonAPIClient: MastodonAPIClient,
        contentDatabase: ContentDatabase
    ) {
        self.environment = environment
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}

public extension NavigationService {
    /// Navigate to an arbitrary URL.
    ///
    /// If it's our URL scheme, we may already know it's for a tag, and can go directly to the tag timeline,
    /// or we may know it's a mention and will ask the server to resolve it as an account.
    ///
    /// If it's a `web+ap` URL, ask the server to resolve the `https` equivalent.
    ///
    /// If it's any other kind of URL, ask the server to resolve it.
    ///
    /// If the server can't resolve it, open it in the browser.
    func item(url: URL) -> AnyPublisher<Navigation, Never> {
        if let appUrl = AppUrl(url: url) {
            switch appUrl {
            case let .tagTimeline(name):
                return Just(.collection(timelineService(timeline: .tag(name))))
                    .eraseToAnyPublisher()

            case let .mention(userUrl):
                return webfinger(url: userUrl, type: .accounts)

            case let .search(searchUrl):
                return webfinger(url: searchUrl, type: nil)
            }
        }

        return webfinger(url: url, type: nil)
    }

    func contextService(id: Status.Id) -> ContextService {
        ContextService(id: id, environment: environment,
                       mastodonAPIClient: mastodonAPIClient,
                       contentDatabase: contentDatabase)
    }

    func profileService(id: Account.Id) -> ProfileService {
        ProfileService(id: id,
                       environment: environment,
                       mastodonAPIClient: mastodonAPIClient,
                       contentDatabase: contentDatabase)
    }

    func profileService(
        account: Account,
        relationship: Relationship? = nil,
        familiarFollowers: [Account] = []
    ) -> ProfileService {
        ProfileService(account: account,
                       relationship: relationship,
                       familiarFollowers: familiarFollowers,
                       environment: environment,
                       mastodonAPIClient: mastodonAPIClient,
                       contentDatabase: contentDatabase)
    }

    func statusService(status: Status) -> StatusService {
        StatusService(environment: environment,
                      status: status,
                      mastodonAPIClient: mastodonAPIClient,
                      contentDatabase: contentDatabase)
    }

    func accountService(account: Account) -> AccountService {
        AccountService(account: account,
                       environment: environment,
                       mastodonAPIClient: mastodonAPIClient,
                       contentDatabase: contentDatabase)
    }

    func familiarFollowersService(familiarFollowers: [Account]) -> FixedAccountListService {
        FixedAccountListService(
            accounts: familiarFollowers,
            accountConfiguration: .withNote,
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase,
            titleComponents: ["account-list.title.familiar-followers"]
        )
    }

    func loadMoreService(loadMore: LoadMore) -> LoadMoreService {
        LoadMoreService(loadMore: loadMore, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func notificationService(notification: MastodonNotification) -> NotificationService {
        NotificationService(
            notification: notification,
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }

    func multiNotificationService(
        notifications: [MastodonNotification],
        notificationType: MastodonNotification.NotificationType,
        date: Date
    ) -> MultiNotificationService {
        MultiNotificationService(
            notificationServices: notifications.map { notification in
                notificationService(notification: notification)
            },
            notificationType: notificationType,
            date: date,
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase
        )
    }

    func conversationService(conversation: Conversation) -> ConversationService {
        ConversationService(
            conversation: conversation,
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }

    func announcementService(announcement: Announcement) -> AnnouncementService {
        AnnouncementService(announcement: announcement,
                            environment: environment,
                            mastodonAPIClient: mastodonAPIClient,
                            contentDatabase: contentDatabase)
    }

    func timelineService(timeline: Timeline) -> TimelineService {
        TimelineService(timeline: timeline,
                        environment: environment,
                        mastodonAPIClient: mastodonAPIClient,
                        contentDatabase: contentDatabase)
    }

    /// Open a report in the web interface.
    func report(id: Report.Id) -> Navigation {
        return .authenticatedWebView(
            AuthenticatedWebViewService(environment: environment),
            mastodonAPIClient.instanceURL.appendingPathComponents("admin", "reports", id)
        )
    }

    /// Edit the user's public profile in the web interface.
    func editProfile() -> Navigation? {
        let url: URL
        switch mastodonAPIClient.apiCapabilities.flavor {
        case nil:
            return nil
        case .mastodon, .glitch, .hometown:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "profile")
        case .pleroma, .akkoma:
            // Akkoma's web UI doesn't support deep linking to settings.
            return nil
        case .gotosocial:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "user", "profile")
        case .calckey, .firefish:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "profile")
        }

        return .authenticatedWebView(
            AuthenticatedWebViewService(environment: environment),
            url
        )
    }

    /// Edit the user's account settings (password, etc.) in the web interface.
    func accountSettings() -> Navigation? {
        let url: URL
        switch mastodonAPIClient.apiCapabilities.flavor {
        case nil:
            return nil
        case .mastodon, .glitch, .hometown:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("auth", "edit")
        case .pleroma, .akkoma:
            // Akkoma's web UI doesn't support deep linking to settings.
            return nil
        case .gotosocial:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "user", "settings")
        case .calckey, .firefish:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "security")
        }

        return .authenticatedWebView(
            AuthenticatedWebViewService(environment: environment),
            url
        )
    }
}

private extension NavigationService {
    func webfinger(url: URL, type: Search.SearchType?) -> AnyPublisher<Navigation, Never> {
        let navigationSubject = PassthroughSubject<Navigation, Never>()

        let request = mastodonAPIClient
            .request(ResultsEndpoint.search(.init(
                query: url.absoluteString,
                type: type
            )))
            .handleEvents(
                receiveSubscription: { _ in navigationSubject.send(.webfingerStart) },
                receiveCompletion: { _ in navigationSubject.send(.webfingerEnd) })
            .map { results -> Navigation in
                if let tag = results.hashtags.first {
                    return .collection(
                        TimelineService(
                            timeline: .tag(tag.name),
                            environment: environment,
                            mastodonAPIClient: mastodonAPIClient,
                            contentDatabase: contentDatabase))
                } else if let account = results.accounts.first {
                    return .profile(profileService(account: account))
                } else if let status = results.statuses.first {
                    return .collection(contextService(id: status.id))
                } else {
                    return .url(url)
                }
            }
            .replaceError(with: .url(url))

        return navigationSubject.merge(with: request).eraseToAnyPublisher()
    }
}
