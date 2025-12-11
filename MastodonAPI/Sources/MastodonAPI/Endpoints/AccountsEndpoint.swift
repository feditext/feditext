// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum AccountsEndpoint {
  case rebloggedBy(id: Status.Id)
  case favouritedBy(id: Status.Id)
  /// https://docs.joinmastodon.org/methods/mutes/
  case mutes
  case blocks
  case accountsFollowers(id: Account.Id)
  case accountsFollowing(id: Account.Id)
  case followRequests
  /// https://docs.joinmastodon.org/methods/directory/
  case directory(local: Bool)
  /// Account search by username or display name only.
  /// - SeeAlso: <https://docs.joinmastodon.org/methods/accounts/#search>
  case search(
    _ q: String,
    resolve: Bool = false,
    following: Bool = false,
    limit: Int? = nil,
    offset: Int? = nil
  )
}

extension AccountsEndpoint: Endpoint {
  public typealias ResultType = [Account]

  public var context: [String] {
    switch self {
    case .rebloggedBy, .favouritedBy:
      return defaultContext + ["statuses"]
    case .mutes, .blocks, .followRequests, .directory:
      return defaultContext
    case .accountsFollowers, .accountsFollowing, .search:
      return defaultContext + ["accounts"]
    }
  }

  public var pathComponentsInContext: [String] {
    switch self {
    case .rebloggedBy(let id):
      return [id, "reblogged_by"]
    case .favouritedBy(let id):
      return [id, "favourited_by"]
    case .mutes:
      return ["mutes"]
    case .blocks:
      return ["blocks"]
    case .accountsFollowers(let id):
      return [id, "followers"]
    case .accountsFollowing(let id):
      return [id, "following"]
    case .followRequests:
      return ["follow_requests"]
    case .directory:
      return ["directory"]
    case .search:
      return ["search"]
    }
  }

  public var queryParameters: [URLQueryItem] {
    switch self {
    case .rebloggedBy,
      .favouritedBy,
      .mutes,
      .blocks,
      .accountsFollowers,
      .accountsFollowing,
      .followRequests:
      return []
    case .directory(let local):
      return [.init(name: "local", value: String(local))]
    case .search(let q, let resolve, let following, let limit, let offset):
      var params = [URLQueryItem(name: "q", value: q)]
      if resolve {
        params.append(.init(name: "resolve", value: "\(resolve)"))
      }
      if following {
        params.append(.init(name: "following", value: "\(following)"))
      }
      if let limit {
        params.append(.init(name: "limit", value: "\(limit)"))
      }
      if let offset {
        params.append(.init(name: "offset", value: "\(offset)"))
      }
      return params
    }
  }

  public var method: HTTPMethod {
    .get
  }

  public var requires: APICapabilityRequirements? {
    switch self {
    case .directory:
      return .mastodonForks("3.0.0") | [
        .fedibird: "0.1.0"
      ]
    case .mutes:
      return .mastodonForks(.assumeAvailable) | [
        .fedibird: "0.1.0",
        .pleroma: .assumeAvailable,
        .akkoma: .assumeAvailable,
        .calckey: .assumeAvailable,
        .firefish: "1.0.0",
        .iceshrimp: "1.0.0",
        .pixelfed: .assumeAvailable,
        .gotosocial: "0.16.0-0",
      ]
    default:
      return nil
    }
  }

  public var fallback: [Account]? { [] }
}
