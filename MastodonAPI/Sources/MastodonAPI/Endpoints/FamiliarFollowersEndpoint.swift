// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// https://docs.joinmastodon.org/methods/accounts/#familiar_followers
public enum FamiliarFollowersEndpoint {
  case familiarFollowers(ids: [Account.Id])
}

extension FamiliarFollowersEndpoint: Endpoint {
  public typealias ResultType = [FamiliarFollowers]

  public var context: [String] {
    return defaultContext + ["accounts", "familiar_followers"]
  }

  public var pathComponentsInContext: [String] {
    []
  }

  public var method: HTTPMethod {
    .get
  }

  public var queryParameters: [URLQueryItem] {
    switch self {
    case .familiarFollowers(let ids):
      return ids.map { URLQueryItem(name: "id[]", value: $0) }
    }
  }

  public var requires: APICapabilityRequirements? {
    .mastodonForks("3.5.0")
  }

  public var fallback: ResultType? { [] }
}
