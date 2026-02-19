// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StatusesEndpoint {
  /// https://docs.joinmastodon.org/methods/timelines/#public
  case timelinesPublic(local: Bool)
  /// https://docs.joinmastodon.org/methods/timelines/#tag
  case timelinesTag(String)
  /// https://docs.joinmastodon.org/methods/timelines/#home
  case timelinesHome
  /// https://docs.joinmastodon.org/methods/timelines/#list
  case timelinesList(id: List.Id)
  case accountsStatuses(id: Account.Id, excludeReplies: Bool, excludeReblogs: Bool, onlyMedia: Bool, pinned: Bool)
  case favourites
  case bookmarks
  /// https://docs.joinmastodon.org/methods/trends/#statuses
  case trends(limit: Int? = nil, offset: Int? = nil)
  /// Retrieve multiple statuses by ID.
  /// May not contain results for every ID if statuses are missing or forbidden to the requester.
  /// https://docs.joinmastodon.org/methods/statuses/#index
  case statuses(_ ids: Set<Status.Id>)

}

extension StatusesEndpoint: Endpoint {
  public typealias ResultType = [Status]

  public var context: [String] {
    switch self {
    case .timelinesPublic, .timelinesTag, .timelinesHome, .timelinesList:
      return defaultContext + ["timelines"]
    case .accountsStatuses:
      return defaultContext + ["accounts"]
    default:
      return defaultContext
    }
  }

  public var pathComponentsInContext: [String] {
    switch self {
    case .timelinesPublic:
      return ["public"]
    case .timelinesTag(let tag):
      return ["tag", tag]
    case .timelinesHome:
      return ["home"]
    case .timelinesList(let id):
      return ["list", id]
    case .accountsStatuses(let id, _, _, _, _):
      return [id, "statuses"]
    case .favourites:
      return ["favourites"]
    case .bookmarks:
      return ["bookmarks"]
    case .trends:
      return ["trends", "statuses"]
    case .statuses:
      return ["statuses"]
    }
  }

  public var queryParameters: [URLQueryItem] {
    switch self {
    case .timelinesPublic(let local):
      return [URLQueryItem(name: "local", value: String(local))]

    case .accountsStatuses(_, let excludeReplies, let excludeReblogs, let onlyMedia, let pinned):
      // Send boolean params only if true.
      // Firefish and Hajkey currently (2023-08-01) can't handle the pinned parameter's presence,
      // and will return an empty list even if pinned=false was requested. See Feditext bug #152.
      var items = [URLQueryItem]()
      if excludeReplies {
        items.append(URLQueryItem(name: "exclude_replies", value: String(excludeReplies)))
      }
      if excludeReblogs {
        items.append(URLQueryItem(name: "exclude_reblogs", value: String(excludeReblogs)))
      }
      if onlyMedia {
        items.append(URLQueryItem(name: "only_media", value: String(onlyMedia)))
      }
      if pinned {
        items.append(URLQueryItem(name: "pinned", value: String(pinned)))
      }
      return items

    case .trends(let limit, let offset):
      return queryParameters(limit, offset)

    case .statuses(let ids):
      return ids.map { id in .init(name: "id[]", value: id) }

    case .timelinesTag,
      .timelinesHome,
      .timelinesList,
      .favourites,
      .bookmarks:
      return []
    }
  }

  public var method: HTTPMethod { .get }

  public var requires: APICapabilityRequirements? {
    switch self {
    case .trends:
      return .mastodonForks("3.5.0") | [
        .calckey: "14.0.0-0",
        .firefish: "1.0.0",
        .iceshrimp: "1.0.0",
      ]

    case .timelinesTag:
      return .mastodonForks(.assumeAvailable) | [
        .pleroma: .assumeAvailable,
        .akkoma: .assumeAvailable,
        .gotosocial: "0.11.0-0",
        .calckey: "14.0.0-0",
        .firefish: "1.0.0",
        .iceshrimp: "1.0.0",
        .pixelfed: .assumeAvailable,
      ]

    case .timelinesList:
      return .mastodonForks(.assumeAvailable) | [
        .pleroma: .assumeAvailable,
        .akkoma: .assumeAvailable,
        .gotosocial: "0.10.0-0",
        .calckey: "14.0.0-0",
        .firefish: "1.0.0",
        .iceshrimp: "1.0.0",
      ]

    case .bookmarks:
      return .mastodonForks(.assumeAvailable) | [
        .pleroma: .assumeAvailable,
        .akkoma: .assumeAvailable,
        .gotosocial: .assumeAvailable,
        .calckey: .assumeAvailable,
        .firefish: .assumeAvailable,
        .iceshrimp: .assumeAvailable,
      ]

    case .statuses:
      return .mastodonForks("4.3.0")

    case .timelinesPublic,
      .timelinesHome,
      .accountsStatuses,
      .favourites:
      return nil
    }
  }

  public var fallback: [Status]? { [] }

  public var notFound: EntityNotFound? {
    switch self {
    case .timelinesPublic,
      .timelinesHome,
      .favourites,
      .bookmarks,
      .trends,
      .statuses:
      // For statuses we don't know which in the set of IDs were not found, so we don't delete any from local storage.
      return nil

    case .timelinesTag(let name):
      return .tag(name)

    case .timelinesList(let id):
      return .list(id)

    case .accountsStatuses(let id, _, _, _, _):
      return .account(id)
    }
  }
}
