// Copyright © 2025 Vyr Cossont. All rights reserved.

import Combine
import DB
import Mastodon
import MastodonAPI

/// Fetch the list of filtered statuses.
/// The v2 filter endpoint is not paged, so we fetch all the IDs from it,
/// and then fetch statuses using bulk (if available) or single status methods.
public final class FilteredStatusesService {
  public let navigationService: NavigationService
  public let titleLocalizationComponents: AnyPublisher<[String], Never>
  public let sections: AnyPublisher<[CollectionSection], Error>

  private let mastodonAPIClient: MastodonAPIClient
  private var statusIDs: Set<Status.Id>?
  private var sectionsSubject = CurrentValueSubject<[CollectionSection], Error>([])

  public init(
    environment: AppEnvironment,
    mastodonAPIClient: MastodonAPIClient,
    contentDatabase: ContentDatabase,
  ) {
    self.mastodonAPIClient = mastodonAPIClient

    navigationService = .init(
      environment: environment,
      mastodonAPIClient: mastodonAPIClient,
      contentDatabase: contentDatabase
    )

    let filteredStatusesTitle =
      switch AppPreferences(environment: environment).statusWord {
      case .post: "filtered-statuses.post"
      case .toot: "filtered-statuses.toot"
      }
    titleLocalizationComponents = Just([filteredStatusesTitle]).eraseToAnyPublisher()

    sections = sectionsSubject.eraseToAnyPublisher()
  }

  // FIXME: (Vyr) doesn't cache or page anything
  private func request() async throws {
    guard mastodonAPIClient.apiCapabilities.supportsV2Filters else {
      assertionFailure("filtered statuses requested when client doesn't support v2 filters")
      return
    }

    guard statusIDs == nil else {
      // Already fetched them.
      return
    }

    var statusIDs = Set<Status.Id>()
    for filter in try await mastodonAPIClient.request(FiltersV2Endpoint.filters) {
      statusIDs.formUnion(filter.statuses.map(\.statusId))
    }
    self.statusIDs = statusIDs

    var statuses = [Status]()
    if StatusesEndpoint.statuses([]).canCallWith(mastodonAPIClient.apiCapabilities) {
      statuses.append(contentsOf: try await mastodonAPIClient.request(StatusesEndpoint.statuses(statusIDs)))
    } else {
      for id in statusIDs {
        statuses.append(try await mastodonAPIClient.request(StatusEndpoint.status(id: id)))
      }
    }
    statuses.sort(by: { $0.id > $1.id })

    sectionsSubject.value = [
      .init(
        items: statuses.map { status in
          .status(
            status,
            .default,
            authorRelationship: nil,
            rebloggerRelationship: nil
          )
        }
      )
    ]
  }
}

extension FilteredStatusesService: CollectionService {
  public func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error> {
    Future {
      try await self.request()
    }
    .flatMap { _ in Empty(outputType: Never.self, failureType: Error.self) }
    .eraseToAnyPublisher()
  }
}
