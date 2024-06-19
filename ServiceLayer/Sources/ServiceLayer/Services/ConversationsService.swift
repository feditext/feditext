// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ConversationsService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let nextPageMaxId: AnyPublisher<String?, Never>
    public let navigationService: NavigationService

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIdSubject = PassthroughSubject<String?, Never>()

    init(environment: AppEnvironment, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        sections = contentDatabase.conversationsPublisher()
            .map { [.init(items: $0.map(CollectionItem.conversation))] }
            .eraseToAnyPublisher()
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        navigationService = NavigationService(
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }
}

public extension ConversationsService {
    func markConversationAsRead(id: Conversation.Id) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(ConversationEndpoint.read(id: id))
            .flatMap { contentDatabase.insert(conversations: [$0]) }
            .eraseToAnyPublisher()
    }

    /// Mark all conversations as read.
    /// There isn't a bulk API method, so we have to do this one by one.
    func markAllConversationsAsRead() async throws {
        var maxId: Conversation.Id?
        /// All of the conversations we fetch in the loop.
        var conversations = Set<Conversation>()
        /// Most recent non-fatal API error.
        var apiError: Error?

        repeat {
            // Get a page of conversations.
            let page: PagedResult<[Conversation]>
            do {
                page = try await mastodonAPIClient.pagedRequest(
                    ConversationsEndpoint.conversations,
                    maxId: maxId
                )
            } catch {
                // An API error while paging means we should stop paging.
                apiError = error
                break
            }
            maxId = page.info.maxId
            conversations.formUnion(page.result)

            // TODO: (Vyr) rate limit conversation marking
            // Mark the unread conversations as read.
            for conversation in page.result where conversation.unread {
                do {
                    conversations.insert(
                        try await mastodonAPIClient.request(
                            ConversationEndpoint.read(id: conversation.id)
                        )
                    )
                } catch {
                    // An API error while marking as read is recoverable.
                    apiError = error
                }
            }
        } while maxId != nil

        // Update the DB with any available conversations.
        try await contentDatabase.insert(conversations: .init(conversations)).finished

        // If there was an API error at any point, rethrow it.
        if let error = apiError {
            throw error
        }
    }
}

extension ConversationsService: CollectionService {
    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.pagedRequest(ConversationsEndpoint.conversations, maxId: maxId, minId: minId)
            .handleEvents(receiveOutput: {
                guard let maxId = $0.info.maxId else { return }

                nextPageMaxIdSubject.send(maxId)
            })
            .flatMap { contentDatabase.insert(conversations: $0.result) }
            .eraseToAnyPublisher()
    }
}
