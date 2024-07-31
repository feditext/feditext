// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public class SearchService: ObservableObject {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let navigationService: NavigationService
    public let nextPageMaxId: AnyPublisher<String?, Never>

    public var query: String = "" {
        didSet {
            newSearch()
        }
    }
    public var type: ResultsEndpoint.Search.SearchType? {
        didSet {
            newSearch()
        }
    }
    public var limit: Int? {
        didSet {
            newSearch()
        }
    }

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let nextPageMaxIdSubject = PassthroughSubject<String?, Never>()
    private let sectionsPublisherSubject = PassthroughSubject<AnyPublisher<[CollectionSection], Error>, Error>()

    private var results: Results = .empty

    init(environment: AppEnvironment, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        navigationService = NavigationService(environment: environment,
                                              mastodonAPIClient: mastodonAPIClient,
                                              contentDatabase: contentDatabase)
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
        sections = sectionsPublisherSubject
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    private func newSearch() {
        results = .empty
        nextPageMaxIdSubject.send(nil)
        sectionsPublisherSubject.send(Just([]).setFailureType(to: Error.self).eraseToAnyPublisher())
    }
}

extension SearchService: CollectionService {
    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        Future { [weak self] in
            try await self?.request(maxId: maxId, minId: minId)
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }

    public func request(maxId: String?, minId: String?) async throws {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }

        let pagedResponse = try await mastodonAPIClient.pagedRequest(
            ResultsEndpoint.search(.init(query: query, type: type)),
            maxId: maxId,
            minId: minId,
            limit: limit
        )
        let page = pagedResponse.result.dedupe()

        if page.isEmpty {
            return
        }

        // No known search API implementers actually use Link headers for paging,
        // so we get the next page's max ID from the appropriate entity type.
        switch type {
        case .accounts:
            nextPageMaxIdSubject.send(page.accounts.lazy.map(\.id).min())
        case .statuses:
            nextPageMaxIdSubject.send(page.statuses.lazy.map(\.id).min())
        default:
            nextPageMaxIdSubject.send(nil)
        }

        try await contentDatabase.insert(results: page).finished

        let accountIDs = page.accounts.map(\.id)
        if !accountIDs.isEmpty {
            let relationships = try await mastodonAPIClient.request(
                RelationshipsEndpoint.relationships(ids: accountIDs)
            )
            try await contentDatabase.insert(relationships: relationships).finished

            let familiarFollowers = try await mastodonAPIClient.request(
                FamiliarFollowersEndpoint.familiarFollowers(ids: accountIDs)
            )
            try await contentDatabase.insert(familiarFollowers: familiarFollowers).finished
        }

        let preAppendCount = results.count
        results = results.appending(page)
        if results.count == preAppendCount {
            // We haven't added any new results, and should stop here.
            // Continuing will update the sections publisher and thus the UI,
            // which will eventually trigger a new update and bring us here again in a loop.
            return
        }

        sectionsPublisherSubject.send(contentDatabase.publisher(results: results, limit: limit))
    }
}
