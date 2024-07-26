// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class MultiNotificationViewModel: ObservableObject {
    public let statusViewModel: StatusViewModel?
    public let accountViewModels: [AccountViewModel]
    public let identityContext: IdentityContext

    private let multiNotificationService: MultiNotificationService
    private let eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>

    init(
        multiNotificationService: MultiNotificationService,
        statusService: StatusService?,
        identityContext: IdentityContext,
        eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>
    ) {
        self.multiNotificationService = multiNotificationService
        if let statusService = statusService {
            self.statusViewModel = StatusViewModel(
                statusService: statusService,
                identityContext: identityContext,
                timeline: nil,
                followedTags: [],
                eventsSubject: eventsSubject
            )
        } else {
            self.statusViewModel = nil
        }
        self.accountViewModels = multiNotificationService.accountServices.map { accountService in
            AccountViewModel(
                accountService: accountService,
                identityContext: identityContext,
                eventsSubject: eventsSubject
            )
        }
        self.identityContext = identityContext
        self.eventsSubject = eventsSubject
    }

    public var count: Int { multiNotificationService.notificationServices.count }
    public var type: MastodonNotification.NotificationType { multiNotificationService.type }
    public var time: String? { multiNotificationService.date.timeAgo }
    public var accessibilityTime: String? { multiNotificationService.date.accessibilityTimeAgo }

    /// Show accounts that performed the action for this notification type.
    public func showAccounts() {
        eventsSubject.send(
            Just(.navigation(.collection(multiNotificationService.accountListService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        )
    }
}
