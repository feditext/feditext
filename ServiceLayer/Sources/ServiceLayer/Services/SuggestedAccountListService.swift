// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

/// Like `AccountListService` but for account suggestions, which have an extra piece of metadata and are not paged.
public struct SuggestedAccountListService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let accountIdsForRelationships: AnyPublisher<Set<Account.Id>, Never>
    public let navigationService: NavigationService
    public let canRefresh = true

    private let listId: String = UUID().uuidString
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let titleComponents: [String]?
    private let accountIdsForRelationshipsSubject = PassthroughSubject<Set<Account.Id>, Never>()

    init(
        environment: AppEnvironment,
        mastodonAPIClient: MastodonAPIClient,
        contentDatabase: ContentDatabase,
        titleComponents: [String]? = nil
    ) {
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        self.titleComponents = titleComponents
        self.sections = contentDatabase.accountListPublisher(id: listId, configuration: .followSuggestion)
        self.accountIdsForRelationships = accountIdsForRelationshipsSubject.eraseToAnyPublisher()
        self.navigationService = NavigationService(
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase
        )
    }

    public func remove(id: Account.Id) -> AnyPublisher<Never, Error> {
        contentDatabase.remove(id: id, from: listId)
    }
}

extension SuggestedAccountListService: CollectionService {
    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(SuggestionsEndpoint.suggestions())
            .flatMap { suggestions in
                contentDatabase.update(suggestions: suggestions)
                    .andThen { contentDatabase.insert(accounts: suggestions.map(\.account), listId: listId) }
            }
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    public var titleLocalizationComponents: AnyPublisher<[String], Never> {
        if let titleComponents = titleComponents {
            return Just(titleComponents).eraseToAnyPublisher()
        } else {
            return Empty().eraseToAnyPublisher()
        }
    }
}
