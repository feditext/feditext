// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

/// Display a thread's context: a focused post and its ancestors and descendants.
public struct ContextService {
    public let sections: AnyPublisher<[CollectionSection], Error>
    public let navigationService: NavigationService

    private let id: Status.Id
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(id: Status.Id,
         environment: AppEnvironment,
         mastodonAPIClient: MastodonAPIClient,
         contentDatabase: ContentDatabase) {
        self.id = id
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        let applyV1Filters = !mastodonAPIClient.supportsV2Filters
        sections = contentDatabase.contextPublisher(id: id, applyV1Filters: applyV1Filters)
        navigationService = NavigationService(environment: environment,
                                              mastodonAPIClient: mastodonAPIClient,
                                              contentDatabase: contentDatabase)
    }
}

extension ContextService: CollectionService {
    public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(StatusEndpoint.status(id: id))
            .catch(contentDatabase.catchNotFound)
            .flatMap(contentDatabase.insert(status:))
            .merge(
                with: mastodonAPIClient.request(ContextEndpoint.context(id: id))
                    .catch(contentDatabase.catchNotFound)
                    .flatMap { contentDatabase.insert(context: $0, parentId: id) }
            )
            .eraseToAnyPublisher()
    }

    public func expand(ids: Set<Status.Id>) -> AnyPublisher<Never, Error> {
        contentDatabase.expand(ids: ids)
    }

    public func collapse(ids: Set<Status.Id>) -> AnyPublisher<Never, Error> {
        contentDatabase.collapse(ids: ids)
    }

    /// An empty context looks weird, so don't display one.
    public var closeWhenEmpty: Bool { true }
}
