// Copyright © 2020 Metabolist. All rights reserved.

import AppMetadata
import Combine
import CombineInterop
import DB
import Foundation
import Mastodon
import MastodonAPI
import os

public struct NotificationsService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let nextPageMaxId: AnyPublisher<String?, Never>
    public let navigationService: NavigationService
    public let announcesNewItems = true

    private let excludeTypes: Set<MastodonNotification.NotificationType>
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let identityDatabase: IdentityDatabase
    private let identityId: Identity.Id
    private let nextPageMaxIdSubject: CurrentValueSubject<String?, Never>

    /// Refers to identity DB because follow-related notifications are a cue to update the follow request count there.
    init(
        excludeTypes: Set<MastodonNotification.NotificationType>,
        environment: AppEnvironment,
        mastodonAPIClient: MastodonAPIClient,
        contentDatabase: ContentDatabase,
        identityDatabase: IdentityDatabase,
        identityId: Identity.Id
    ) {
        self.excludeTypes = excludeTypes
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        self.identityDatabase = identityDatabase
        self.identityId = identityId

        let nextPageMaxIdSubject = CurrentValueSubject<String?, Never>(String(Int.max))
        self.nextPageMaxIdSubject = nextPageMaxIdSubject

        let appPreferences = AppPreferences(environment: environment)
        self.sections = contentDatabase.notificationsPublisher(excludeTypes: excludeTypes)
            .map { sections in
                if appPreferences.notificationGrouping {
                    return sections.map { section in
                        CollectionSection(
                            items: NotificationsService.groupNotificationSectionItems(section.items),
                            searchScope: section.searchScope
                        )
                    }
                } else {
                    return sections
                }
            }
            .handleEvents(receiveOutput: {
                guard case let .notification(notification, _, _) = $0.last?.items.last,
                      let nextPageMaxId = nextPageMaxIdSubject.value,
                      notification.id < nextPageMaxId
                else { return }

                nextPageMaxIdSubject.send(notification.id)
            })
            .eraseToAnyPublisher()

        self.nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        self.navigationService = NavigationService(
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase
        )
    }
}

extension NotificationsService: CollectionService {
    public var markerTimeline: Marker.Timeline? { excludeTypes.isEmpty ? .notifications : nil }

    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        Future(asyncThrows: {
            try await request(maxId: maxId, minId: minId)
        })
        .flatMap { Empty<Never, Error>() }
        .eraseToAnyPublisher()
    }

    public func request(maxId: String?, minId: String?) async throws {
        let page = try await mastodonAPIClient.pagedRequest(
            NotificationsEndpoint.notifications(excludeTypes: excludeTypes),
            maxId: maxId,
            minId: minId
        )

        if let maxId = page.info.maxId,
           let nextPageMaxId = nextPageMaxIdSubject.value,
           maxId < nextPageMaxId {
            nextPageMaxIdSubject.send(maxId)
        }

        let notifications = page.result

        try await contentDatabase
            .insert(notifications: notifications)
            .finished

        let logger = Logger(subsystem: AppMetadata.bundleIDBase, category: #fileID)

        // If any of the notifications are follows or follow requests, update the follow request count.
        if notifications.contains(where: { $0.type == .followRequest || $0.type == .follow }) {
            do {
                let account = try await mastodonAPIClient.request(AccountEndpoint.verifyCredentials)
                try await identityDatabase
                    .updateAccount(account, id: identityId)
                    .finished
            } catch {
                logger.error("Nonfatal error updating follow request count: \(error, privacy: .public)")
            }
        }

        // If any of the notifications are reports with rule IDs, update rules.
        if notifications.contains(where: { !($0.report?.ruleIds?.isEmpty ?? true) }) {
            do {
                let rules = try await mastodonAPIClient.request(RulesEndpoint.rules)
                try await contentDatabase
                    .update(rules: rules)
                    .finished
            } catch {
                logger.error("Nonfatal error updating instance rules: \(error, privacy: .public)")
            }
        }
    }

    public func requestMarkerLastReadId() -> AnyPublisher<CollectionItem.Id, Error> {
        mastodonAPIClient.request(MarkersEndpoint.get([.notifications]))
            .compactMap { $0.values.first?.lastReadId }
            .eraseToAnyPublisher()
    }

    public func setMarkerLastReadId(_ id: CollectionItem.Id) -> AnyPublisher<CollectionItem.Id, Error> {
        mastodonAPIClient.request(MarkersEndpoint.post([.notifications: id]))
            .compactMap { $0.values.first?.lastReadId }
            .eraseToAnyPublisher()
    }
}

// MARK: - notification grouping implementation

private typealias NotificationType = MastodonNotification.NotificationType

private extension NotificationsService {
    /// Group notifications into multiNotifications where possible.
    static func groupNotificationSectionItems(_ items: [CollectionItem]) -> [CollectionItem] {
        var groupedItemsWithDates: [(Date, CollectionItem)] = []

        let notifications = items.compactMap { GroupableNotification($0) }
        let byWindow: [Date: [GroupableNotification]] = .init(grouping: notifications) { $0.window }
        for forWindow in byWindow.values {
            // Includes the nil status ID for non-status notifications like follows and reports.
            let byStatus: [Status.Id?: [GroupableNotification]] = .init(grouping: forWindow) { $0.statusId }
            for forStatus in byStatus.values {
                let byType: [NotificationType: [GroupableNotification]] = .init(grouping: forStatus) { $0.type }
                for (notificationType, var forType) in byType {
                    if groupableTypes.contains(notificationType) && forType.count > 1 {
                        // Group these into a multiNotification item.

                        // De-duplicate so we have one notification per account.
                        // Handles fav, unfav, fav sequences.
                        forType.sort()
                        var seenAccountIds: Set<Account.Id> = .init()
                        var dedupedByUser: [GroupableNotification] = []
                        for notification in forType {
                            if seenAccountIds.contains(notification.accountId) {
                                continue
                            }
                            dedupedByUser.append(notification)
                            seenAccountIds.insert(notification.accountId)
                        }

                        let newest = dedupedByUser[0]
                        groupedItemsWithDates.append((
                            newest.date,
                            .multiNotification(
                                dedupedByUser.map { $0.mastodonNotification },
                                notificationType,
                                newest.date,
                                newest.mastodonNotification.status
                            )
                        ))
                    } else {
                        // Pass through non-groupable notifications and single groupable notifications.
                        for notification in forType {
                            groupedItemsWithDates.append((
                                notification.date,
                                .notification(
                                    notification.mastodonNotification,
                                    notification.rules,
                                    notification.statusConfiguration
                                )
                            ))
                        }
                    }
                }
            }
        }

        groupedItemsWithDates.sort { (lhs, rhs) in lhs.0 > rhs.0 }
        return groupedItemsWithDates.map { (_, item) in item }
    }
}

/// Notification types that make sense to group. These don't require action from the user.
private let groupableTypes: [MastodonNotification.NotificationType] = [
    .favourite,
    .reblog,
    .follow
]

private struct GroupableNotification {
    let mastodonNotification: MastodonNotification
    /// Only reports actually have these.
    let rules: [Rule]
    // TODO: (Vyr) should subscribed-user status notifications also have these?
    /// Only mentions actually have these.
    let statusConfiguration: CollectionItem.StatusConfiguration?

    init?(_ item: CollectionItem) {
        if case let .notification(mastodonNotification, rules, statusConfiguration) = item {
            self.mastodonNotification = mastodonNotification
            self.rules = rules
            self.statusConfiguration = statusConfiguration
        } else {
            assertionFailure("Should only be called with CollectionItems.notification")
            return nil
        }
    }

    var statusId: Status.Id? { mastodonNotification.status?.id }
    var type: NotificationType { mastodonNotification.type }
    var accountId: Account.Id { mastodonNotification.account.id }
    var date: Date { mastodonNotification.createdAt }
    /// Group notifications from the same day.
    /// Prevents groups from changing much if the user loads many old notifications.
    var window: Date { Calendar.current.startOfDay(for: date) }
}

extension GroupableNotification: Comparable {
    static func < (lhs: GroupableNotification, rhs: GroupableNotification) -> Bool {
        lhs.date > rhs.date
    }
}
