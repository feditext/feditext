// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum CardsEndpoint {
  /// https://docs.joinmastodon.org/methods/trends/#links
  case trends(limit: Int? = nil, offset: Int? = nil)
}

extension CardsEndpoint: Endpoint {
  public typealias ResultType = [Card]

  public var pathComponentsInContext: [String] {
    switch self {
    case .trends: return ["trends", "links"]
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .trends: return .get
    }
  }

  public var queryParameters: [URLQueryItem] {
    switch self {
    case .trends(let limit, let offset):
      return queryParameters(limit, offset)
    }
  }

  public var requires: APICapabilityRequirements? {
    switch self {
    case .trends:
      return .mastodonForks("3.5.0")
    }
  }

  public var fallback: [Card]? { [] }
}
