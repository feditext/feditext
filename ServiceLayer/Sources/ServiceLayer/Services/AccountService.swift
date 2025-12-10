// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountService {
  public let account: Account
  public let navigationService: NavigationService

  private let environment: AppEnvironment
  private let mastodonAPIClient: MastodonAPIClient
  private let contentDatabase: ContentDatabase

  public init(
    account: Account,
    identityProofs: [IdentityProof] = [],
    featuredTags: [FeaturedTag] = [],
    environment: AppEnvironment,
    mastodonAPIClient: MastodonAPIClient,
    contentDatabase: ContentDatabase
  ) {
    self.account = account
    navigationService = NavigationService(
      environment: environment,
      mastodonAPIClient: mastodonAPIClient,
      contentDatabase: contentDatabase)
    self.environment = environment
    self.mastodonAPIClient = mastodonAPIClient
    self.contentDatabase = contentDatabase
  }
}

extension AccountService {
  public var isLocal: Bool {
    URL(string: account.url)?.host == mastodonAPIClient.instanceURL.host
  }

  public var domain: String? { URL(string: account.url)?.host }

  public func lists() -> AnyPublisher<[List], Error> {
    mastodonAPIClient.request(ListsEndpoint.listsWithAccount(id: account.id))
  }

  public func addToList(id: List.Id) -> AnyPublisher<Never, Error> {
    mastodonAPIClient.request(EmptyEndpoint.addAccountsToList(id: id, accountIds: [account.id]))
      .ignoreOutput()
      .eraseToAnyPublisher()
  }

  public func removeFromList(id: List.Id) -> AnyPublisher<Never, Error> {
    mastodonAPIClient.request(EmptyEndpoint.removeAccountsFromList(id: id, accountIds: [account.id]))
      .ignoreOutput()
      .eraseToAnyPublisher()
  }

  public func follow() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsFollow(id: account.id))
  }

  public func unfollow() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsUnfollow(id: account.id))
      .collect()
      .flatMap { _ in contentDatabase.unfollow(id: account.id) }
      .eraseToAnyPublisher()
  }

  public func hideReblogs() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsFollow(id: account.id, showReblogs: false))
  }

  public func showReblogs() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsFollow(id: account.id, showReblogs: true))
  }

  public func notify() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsFollow(id: account.id, notify: true))
  }

  public func unnotify() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsFollow(id: account.id, notify: false))
  }

  public func block() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsBlock(id: account.id))
      .collect()
      .flatMap { _ in contentDatabase.block(id: account.id) }
      .eraseToAnyPublisher()
  }

  public func unblock() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsUnblock(id: account.id))
  }

  public func mute(notifications: Bool, duration: Int) -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsMute(id: account.id, notifications: notifications, duration: duration))
      .collect()
      .flatMap { _ in contentDatabase.mute(id: account.id) }
      .eraseToAnyPublisher()
  }

  public func unmute() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsUnmute(id: account.id))
  }

  public func pin() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsPin(id: account.id))
  }

  public func unpin() -> AnyPublisher<Never, Error> {
    relationshipAction(.accountsUnpin(id: account.id))
  }

  public func set(note: String) -> AnyPublisher<Never, Error> {
    relationshipAction(.note(note, id: account.id))
  }

  public func acceptFollowRequest() -> AnyPublisher<Never, Error> {
    relationshipAction(.acceptFollowRequest(id: account.id))
  }

  public func rejectFollowRequest() -> AnyPublisher<Never, Error> {
    relationshipAction(.rejectFollowRequest(id: account.id))
  }

  public func removeFollowSuggestion() -> AnyPublisher<Never, Error> {
    removeFollowSuggestionAction(id: account.id)
  }

  public func report(_ elements: ReportElements) -> AnyPublisher<Never, Error> {
    mastodonAPIClient.request(ReportEndpoint.create(elements)).ignoreOutput().eraseToAnyPublisher()
  }

  public func domainBlock() -> AnyPublisher<Never, Error> {
    guard let domain = domain else { return Fail(error: URLError(.badURL)).eraseToAnyPublisher() }

    return domainAction(EmptyEndpoint.blockDomain(domain))
  }

  public func domainUnblock() -> AnyPublisher<Never, Error> {
    guard let domain = domain else { return Fail(error: URLError(.badURL)).eraseToAnyPublisher() }

    return domainAction(EmptyEndpoint.unblockDomain(domain))
  }

  public func followingService() -> AccountListService {
    AccountListService(
      endpoint: .accountsFollowing(id: account.id),
      environment: environment,
      mastodonAPIClient: mastodonAPIClient,
      contentDatabase: contentDatabase,
      titleComponents: ["account.followed-by-%@", "@".appending(account.acct)])
  }

  public func followersService() -> AccountListService {
    AccountListService(
      endpoint: .accountsFollowers(id: account.id),
      environment: environment,
      mastodonAPIClient: mastodonAPIClient,
      contentDatabase: contentDatabase,
      titleComponents: ["account.%@-followers", "@".appending(account.acct)])
  }
}

extension AccountService {
  fileprivate func relationshipAction(_ endpoint: RelationshipEndpoint) -> AnyPublisher<Never, Error> {
    mastodonAPIClient.request(endpoint)
      .flatMap { contentDatabase.insert(relationships: [$0]) }
      .eraseToAnyPublisher()
  }

  fileprivate func domainAction(_ endpoint: EmptyEndpoint) -> AnyPublisher<Never, Error> {
    mastodonAPIClient.request(endpoint)
      .flatMap { _ in mastodonAPIClient.request(RelationshipsEndpoint.relationships(ids: [account.id])) }
      .flatMap { contentDatabase.insert(relationships: $0) }
      .ignoreOutput()
      .eraseToAnyPublisher()
  }

  fileprivate func removeFollowSuggestionAction(id: Account.Id) -> AnyPublisher<Never, Error> {
    mastodonAPIClient.request(EmptyEndpoint.removeFollowSuggestion(id: id))
      .flatMap { _ in contentDatabase.remove(suggestion: id) }
      .ignoreOutput()
      .eraseToAnyPublisher()
  }
}
