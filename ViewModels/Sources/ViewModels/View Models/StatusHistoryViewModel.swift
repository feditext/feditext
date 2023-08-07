// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public struct StatusHistoryViewModel {
    public let identityContext: IdentityContext
    public let versions: [Version]

    private let navigationService: NavigationService
    private let eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>

    public init(
        identityContext: IdentityContext,
        navigationService: NavigationService,
        eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>,
        history: [StatusEdit]
    ) {
        self.identityContext = identityContext
        self.navigationService = navigationService
        self.eventsSubject = eventsSubject
        self.versions = history.enumerated().map { id, edit in Version(id, edit)}
    }

    public func openURL(_ url: URL) {
        eventsSubject.send(
            navigationService.lookup(url: url, identityId: identityContext.identity.id)
                .map { .navigation($0) }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        )
    }

    public var statusWord: AppPreferences.StatusWord { identityContext.appPreferences.statusWord }

    /// Sub view model for an individual edit of a status.
    public struct Version: Identifiable, Hashable {
        public let id: Int
        public let date: Date
        public let emojis: [Emoji]
        public let spoiler: String?
        public let content: NSAttributedString

        init(
            _ id: Int,
            _ edit: StatusEdit
        ) {
            self.id = id
            self.date = edit.createdAt
            self.emojis = edit.emojis
            self.spoiler = edit.spoilerText.isEmpty ? nil : edit.spoilerText
            self.content = edit.content.attributed
        }

        public static func == (lhs: Version, rhs: Version) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
