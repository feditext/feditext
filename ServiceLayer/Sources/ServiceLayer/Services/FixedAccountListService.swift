// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

/// Like `AccountListService` but backed by a fixed list of accounts.
public struct FixedAccountListService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let accountIdsForRelationships: AnyPublisher<Set<Account.Id>, Never>
    public let navigationService: NavigationService
    public let canRefresh = false

    private let listId: String
    private let titleComponents: [String]?

    init(
        accounts: [Account],
        accountConfiguration: CollectionItem.AccountConfiguration,
        environment: AppEnvironment,
        mastodonAPIClient: MastodonAPIClient,
        contentDatabase: ContentDatabase,
        titleComponents: [String]? = nil
    ) {
        let listId = UUID().uuidString
        self.listId = listId
        // Insert the accounts into a new list and then return a publisher for that list.
        self.sections = contentDatabase.insert(accounts: accounts, listId: listId)
            .andThen {
                contentDatabase.accountListPublisher(id: listId, configuration: accountConfiguration)
            }
            .eraseToAnyPublisher()
        self.accountIdsForRelationships = Just(Set(accounts.map { $0.id })).eraseToAnyPublisher()
        self.navigationService = NavigationService(
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase
        )
        self.titleComponents = titleComponents
    }
}

extension FixedAccountListService: CollectionService {
    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        Empty().eraseToAnyPublisher()
    }

    public var titleLocalizationComponents: AnyPublisher<[String], Never> {
        if let titleComponents = titleComponents {
            return Just(titleComponents).eraseToAnyPublisher()
        } else {
            return Empty().eraseToAnyPublisher()
        }
    }
}
