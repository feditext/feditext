// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ExploreService {
    public let navigationService: NavigationService

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(environment: AppEnvironment, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        navigationService = NavigationService(
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase
        )
    }
}

public extension ExploreService {
    func fetchTrendingTags() -> AnyPublisher<[Tag], Error> {
        if TagsEndpoint.trends().canCallWith(mastodonAPIClient.apiCapabilities) {
            return mastodonAPIClient.request(TagsEndpoint.trends())
        } else {
            return mastodonAPIClient.request(TagsEndpoint.trendsLegacy())
        }
    }

    func fetchTrendingLinks() -> AnyPublisher<[Card], Error> {
        mastodonAPIClient.request(CardsEndpoint.trends())
    }

    func fetchTrendingStatuses() -> AnyPublisher<[Status], Error> {
        mastodonAPIClient.request(StatusesEndpoint.trends())
    }

    func fetchRecommendedStatuses() -> AnyPublisher<[Status], Error> {
        // Pixelfed doesn't sort its random daily SFW recommendations, so we have to.
        return mastodonAPIClient.request(Pixelfed.DiscoverEndpoint.posts)
            .map { $0.posts.sorted(by: { lhs, rhs in lhs.createdAt > rhs.createdAt }) }
            .eraseToAnyPublisher()
    }
}
