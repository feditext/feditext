// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ProfileService {
    public let profilePublisher: AnyPublisher<Profile, Error>

    private let id: Account.Id
    private let environment: AppEnvironment
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(account: Account,
         relationship: Relationship?,
         familiarFollowers: [Account],
         environment: AppEnvironment,
         mastodonAPIClient: MastodonAPIClient,
         contentDatabase: ContentDatabase) {
        self.init(
            id: account.id,
            account: account,
            relationship: relationship,
            familiarFollowers: familiarFollowers,
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }

    public init(id: Account.Id,
         environment: AppEnvironment,
         mastodonAPIClient: MastodonAPIClient,
         contentDatabase: ContentDatabase) {
        self.init(id: id,
                  account: nil,
                  relationship: nil,
                  familiarFollowers: [],
                  environment: environment,
                  mastodonAPIClient: mastodonAPIClient,
                  contentDatabase: contentDatabase)
    }

    private init(
        id: Account.Id,
        account: Account?,
        relationship: Relationship?,
        familiarFollowers: [Account],
        environment: AppEnvironment,
        mastodonAPIClient: MastodonAPIClient,
        contentDatabase: ContentDatabase) {
        self.id = id
        self.environment = environment
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase

        var profilePublisher = contentDatabase.profilePublisher(id: id)

        if let account = account {
            profilePublisher = profilePublisher
                .merge(
                    with: Just(Profile(
                        account: account,
                        relationship: relationship,
                        familiarFollowers: familiarFollowers
                    ))
                    .setFailureType(to: Error.self)
                )
                .removeDuplicates()
                .eraseToAnyPublisher()
        }

        self.profilePublisher = profilePublisher
    }
}

public extension ProfileService {
    func timelineService(profileCollection: ProfileCollection) -> TimelineService {
        TimelineService(
            timeline: .profile(accountId: id, profileCollection: profileCollection),
            environment: environment,
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
    }

    func fetchProfile() -> AnyPublisher<Never, Error> {
        Publishers.Merge5(
            mastodonAPIClient.request(AccountEndpoint.accounts(id: id))
                .flatMap { contentDatabase.insert(accounts: [$0]) },
            mastodonAPIClient.request(RelationshipsEndpoint.relationships(ids: [id]))
                .flatMap { contentDatabase.insert(relationships: $0) },
            mastodonAPIClient.request(FamiliarFollowersEndpoint.familiarFollowers(ids: [id]))
                .flatMap { contentDatabase.insert(familiarFollowers: $0) },
            mastodonAPIClient.request(IdentityProofsEndpoint.identityProofs(id: id))
                .catch { _ in Empty() }
                .flatMap { contentDatabase.insert(identityProofs: $0, id: id) },
            mastodonAPIClient.request(FeaturedTagsEndpoint.featuredTags(id: id))
                .catch { _ in Empty() }
                .flatMap { contentDatabase.insert(featuredTags: $0, id: id) })
            .eraseToAnyPublisher()
    }

    func fetchPinnedStatuses() -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(
            StatusesEndpoint.accountsStatuses(
                id: id,
                excludeReplies: true,
                excludeReblogs: true,
                onlyMedia: false,
                pinned: true))
            .flatMap { contentDatabase.insert(pinnedStatuses: $0, accountId: id) }
            .eraseToAnyPublisher()
    }
}
