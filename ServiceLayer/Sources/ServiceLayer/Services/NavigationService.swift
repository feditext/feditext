// Copyright © 2020 Metabolist. All rights reserved.

import AppUrls
import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import os

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
    /// Navigate to an arbitrary URL. Current identity is used as part of a cache key.
    ///
    /// If it's our URL scheme, we may already know it's for a tag, and can go directly to the tag timeline,
    /// or we may know it's a mention and will ask the server to resolve it as an account.
    ///
    /// If it's a `web+ap` URL, ask the server to resolve the `https` equivalent.
    ///
    /// If it's any other kind of URL, ask the server to resolve it.
    ///
    /// If the server can't resolve it, open it in the browser.
    func lookup(url: URL, identityId: Identity.Id) -> AnyPublisher<Navigation, Never> {
        if let appUrl = AppUrl(url: url) {
            switch appUrl {
            case let .tagTimeline(name):
                return Just(.collection(timelineService(timeline: .tag(name))))
                    .eraseToAnyPublisher()

            case let .mention(userUrl):
                return lookup(url: userUrl, identityId: identityId, type: .accounts)

            case let .search(searchUrl):
                return lookup(url: searchUrl, identityId: identityId, type: nil)
            }
        }

        return lookup(url: url, identityId: identityId, type: nil)
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
        case .mastodon, .glitch, .hometown, .fedibird:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "profile")
        case .pleroma, .akkoma:
            // Akkoma's web UI doesn't support deep linking to settings.
            return nil
        case .gotosocial:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "user", "profile")
        case .calckey, .firefish, .iceshrimp:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "profile")
        case .snac:
            // TODO: (Vyr) snac support: does snac even have a web settings UI?
            return nil
        case .pixelfed:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "home")
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
        case .mastodon, .glitch, .hometown, .fedibird:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("auth", "edit")
        case .pleroma, .akkoma:
            // Akkoma's web UI doesn't support deep linking to settings.
            return nil
        case .gotosocial:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "user", "settings")
        case .calckey, .firefish, .iceshrimp:
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "security")
        case .snac:
            // TODO: (Vyr) snac support: does snac even have a web settings UI?
            return nil
        case .pixelfed:
            // Pixelfed has multiple pages for password, 2FA, etc. best reached from the profile settings page.
            url = mastodonAPIClient.instanceURL.appendingPathComponents("settings", "home")
        }

        return .authenticatedWebView(
            AuthenticatedWebViewService(environment: environment),
            url
        )
    }

    /// Debugging aid: clear the cache.
    static func clearCache() {
        navigationCache.removeAllObjects()
    }
}

private extension NavigationService {
    static var navigationCache = NSCache<NavigationCacheKey, NavigationCacheValue>()

    /// Look up a URL in the navigation cache, content database, and WebFinger.
    func lookup(url: URL, identityId: Identity.Id, type: Search.SearchType?) -> AnyPublisher<Navigation, Never> {
        let cacheKey = NavigationCacheKey(identityId: identityId, url: url)

        // Check the cache.
        if let cached = Self.navigationCache.object(forKey: cacheKey) {
            switch cached.result {
            case let .account(id):
                return Just(.profile(profileService(id: id))).eraseToAnyPublisher()
            case let .status(id):
                return Just(.collection(contextService(id: id))).eraseToAnyPublisher()
            case let .tag(name):
                return Just(.collection(timelineService(timeline: .tag(name)))).eraseToAnyPublisher()
            case .url:
                return Just(.url(url)).eraseToAnyPublisher()
            }
        }

        return dbLookup(url: url, type: type, cacheKey: cacheKey)
            .catch { err in
                Logger().warning("DB error while resolving URL, falling back to WebFinger: \(err)")
                return Empty<Navigation, Never>()
            }
            .collect()
            .flatMap { navigations in
                assert(navigations.count <= 1)
                if let navigation = navigations.first {
                    return Just(navigation).eraseToAnyPublisher()
                }

                // Didn't find anything in the DB. Do a WebFinger lookup.
                return webfinger(url: url, type: type, cacheKey: cacheKey)
            }
            .eraseToAnyPublisher()
    }

    /// Look up a URL in the content database.
    /// Returns up to one value.
    /// Caches successful lookups.
    func dbLookup(
        url: URL,
        type: Search.SearchType?,
        cacheKey: NavigationCacheKey
    ) -> AnyPublisher<Navigation, Error> {
        let idPublisher: AnyPublisher<URLLookupResult, Error>
        switch type {
        case .none:
            idPublisher = contentDatabase.lookup(url: url)
        case .accounts:
            idPublisher = contentDatabase.lookup(accountURL: url)
                .map { URLLookupResult.account($0) }
                .eraseToAnyPublisher()
        case .statuses:
            idPublisher = contentDatabase.lookup(statusURL: url)
                .map { URLLookupResult.status($0) }
                .eraseToAnyPublisher()
        case .hashtags:
            // We don't currently store hashtags as a DB table so we're guaranteed not to find anything.
            idPublisher = Empty<URLLookupResult, Error>()
                .eraseToAnyPublisher()
        }

        return idPublisher
            .map { urlLookupResult in
                Self.navigationCache.setObject(.init(urlLookupResult), forKey: cacheKey)
                switch urlLookupResult {
                case let .account(id):
                    return .profile(profileService(id: id))
                case let .status(id):
                    return .collection(contextService(id: id))
                }
            }
            .eraseToAnyPublisher()
    }

    /// Asks the instance server to resolve this URL using WebFinger.
    /// Emits multiple navigation events to start and stop the loading indicator as well as return the result.
    /// Caches successful lookups.
    func webfinger(
        url: URL,
        type: Search.SearchType?,
        cacheKey: NavigationCacheKey
    ) -> AnyPublisher<Navigation, Never> {
        let navigationSubject = PassthroughSubject<Navigation, Never>()
        let urlString = url.absoluteString

        let request = mastodonAPIClient
            .request(ResultsEndpoint.search(.init(
                query: urlString,
                type: type
            )))
            .handleEvents(
                receiveSubscription: { _ in navigationSubject.send(.webfingerStart) },
                receiveCompletion: { _ in navigationSubject.send(.webfingerEnd) })
            .map { results -> Navigation in
                // first(where:) prevents us from accidentally caching a result that merely mentions, not is, the URL.
                if let tag = results.hashtags.first(where: { $0.url.url == url }) {
                    Self.navigationCache.setObject(.init(tag), forKey: cacheKey)
                    return .collection(timelineService(timeline: .tag(tag.name)))
                } else if let account = results.accounts.first(where: { $0.url == urlString }) {
                    Self.navigationCache.setObject(.init(account), forKey: cacheKey)
                    return .profile(profileService(account: account))
                } else if let status = results.statuses.first(where: { $0.url == urlString || $0.uri == urlString }) {
                    Self.navigationCache.setObject(.init(status), forKey: cacheKey)
                    return .collection(contextService(id: status.id))
                } else {
                    Self.navigationCache.setObject(.url, forKey: cacheKey)
                    return .url(url)
                }
            }
            // Do not cache errors.
            // Note that GtS will throw a 500 on trying to look up an URL it can't find anything for,
            // even though the call was successful.
            // TODO: (Vyr) navigation cache: submit patch to GtS?
            .replaceError(with: .url(url))

        return navigationSubject.merge(with: request).eraseToAnyPublisher()
    }
}

/// Has to be a class to use `NSCache`.
private final class NavigationCacheKey: NSObject {
    let identityId: Identity.Id
    let url: URL

    init(identityId: Identity.Id, url: URL) {
        self.identityId = identityId
        self.url = url
    }

    // `NSCache` is an antique that ignores `Hashable`.
    // See https://medium.com/anysuggestion/how-to-use-custom-type-as-a-key-for-nscache-9bdbee02a8f1

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NavigationCacheKey else { return false }

        return identityId == other.identityId && url == other.url
    }

    override var hash: Int {
        identityId.hashValue ^ url.hashValue
    }
}

/// Has to be a class to use `NSCache`.
private final class NavigationCacheValue {
    let result: WebfingerResult

    init(_ account: Account) {
        self.result = .account(account.id)
    }

    init(_ status: Status) {
        self.result = .status(status.id)
    }

    init(_ tag: Tag) {
        self.result = .tag(tag.name)
    }

    init(_ urlLookupResult: URLLookupResult) {
        switch urlLookupResult {
        case let .account(id):
            self.result = .account(id)
        case let .status(id):
            self.result = .status(id)
        }
    }

    init() {
        self.result = .url
    }

    /// We will probably have a lot of these.
    static let url: NavigationCacheValue = NavigationCacheValue()
}

private enum WebfingerResult {
    case account(_ id: Account.Id)
    case status(_ id: Status.Id)
    case tag(_ name: Tag.Name)
    case url
}
