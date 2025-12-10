// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum RelationshipsEndpoint {
  case relationships(ids: [Account.Id])
}

extension RelationshipsEndpoint: Endpoint {
  public typealias ResultType = [Relationship]

  public var pathComponentsInContext: [String] {
    ["accounts", "relationships"]
  }

  public var queryParameters: [URLQueryItem] {
    switch self {
    case .relationships(let ids):
      return ids.map { URLQueryItem(name: "id[]", value: $0) }
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .relationships:
      return .get
    }
  }

  public var fallback: [Relationship]? { [] }
}
