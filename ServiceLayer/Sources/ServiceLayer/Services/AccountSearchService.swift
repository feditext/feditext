// Copyright © 2025 Vyr Cossont. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

/// Service for the account autocomplete search API.
/// - SeeAlso: largely derived from ``SearchService``.
public final class AccountSearchService: ObservableObject, CollectionService {
  public let sections: AnyPublisher<[CollectionSection], Error>
  public let navigationService: NavigationService
  /// Since the underlying endpoint doesn't use ID paging, this is actually the string value of the next page's offset.
  public let nextPageMaxId: AnyPublisher<String?, Never>

  public var query: String = "" {
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
  private let nextPageOffsetSubject = PassthroughSubject<Int?, Never>()
  private let sectionsPublisherSubject = PassthroughSubject<AnyPublisher<[CollectionSection], Error>, Error>()

  /// List ID for an account list in the database where we accumulate the results of the current search.
  private var listID = UUID().uuidString
  private var accounts = [Account]()

  init(environment: AppEnvironment, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
    self.mastodonAPIClient = mastodonAPIClient
    self.contentDatabase = contentDatabase
    navigationService = NavigationService(
      environment: environment,
      mastodonAPIClient: mastodonAPIClient,
      contentDatabase: contentDatabase
    )
    nextPageMaxId = nextPageOffsetSubject.map { x in x.map(\.description) }.eraseToAnyPublisher()
    sections =
      sectionsPublisherSubject
      .switchToLatest()
      .eraseToAnyPublisher()
  }

  private func newSearch() {
    listID = UUID().uuidString
    accounts = []
    nextPageOffsetSubject.send(nil)
    sectionsPublisherSubject.send(Just([]).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
    Future { [weak self] in
      try await self?.request(maxId: maxId, minId: minId)
    }
    .ignoreOutput()
    .eraseToAnyPublisher()
  }

  public func request(maxId: String?, minId: String?) async throws {
    guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }

    let page = try await mastodonAPIClient.request(
      AccountsEndpoint.search(
        query,
        resolve: false,
        following: false,
        limit: limit,
        offset: maxId.flatMap(Int.init)
      )
    )
    if page.isEmpty { return }

    nextPageOffsetSubject.send(accounts.count)
    try await contentDatabase.insert(accounts: page, listId: listID).finished
    // Note: unlike `SearchService`, the published section won't have a search scope.
    // This doesn't matter because section scopes are only used by the Explore tab, which doesn't use this service.
    sectionsPublisherSubject.send(
      contentDatabase.accountListPublisher(
        id: listID,
        configuration: .withoutNote,
      )
    )
  }
}
