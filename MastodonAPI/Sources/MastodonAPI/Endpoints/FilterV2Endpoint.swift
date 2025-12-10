// Copyright © 2025 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

// TODO: (Vyr) fill out other filters v2 endpoints
public enum FilterV2Endpoint {
  case get(filterID: FilterV2.ID)

  case create(
    title: String,
    context: [Filter.Context],
    action: FilterV2.Action,
    expiresIn: Date?
  )
}

extension FilterV2Endpoint: Endpoint {
  public typealias ResultType = FilterV2

  public var APIVersion: String { "v2" }

  public var context: [String] {
    defaultContext + ["filters"]
  }

  public var pathComponentsInContext: [String] {
    switch self {
    case .get(let filterID):
      [filterID]

    case .create:
      []
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .get:
      .get

    case .create:
      .post
    }
  }

  public var jsonBody: [String: Any]? {
    switch self {
    case .create(
      let
        title,
      let
        context,
      let
        action,
      let
        expiresIn
    ):
      var object: [String: Any] = [
        "title": title,
        "context": context.map(\.rawValue),
        "filter_action": action.rawValue,
      ]

      if let expiresIn {
        object["expires_in"] = Int(expiresIn.timeIntervalSinceNow)
      }

      return object

    case .get:
      return nil
    }
  }

  public var requires: APICapabilityRequirements? {
    FiltersV2Endpoint.filters.requires
  }
}
