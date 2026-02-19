// Copyright © 2025 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum FilterV2StatusEndpoint {
  case create(filterID: FilterV2.ID, statusID: Status.ID)
}

extension FilterV2StatusEndpoint: Endpoint {
  public typealias ResultType = FilterV2.Status

  public var apiVersion: String { "v2" }

  public var context: [String] {
    defaultContext + ["filters"]
  }

  public var pathComponentsInContext: [String] {
    switch self {
    case .create(let filterID, _):
      [filterID, "statuses"]
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .create:
      .post
    }
  }

  public var jsonBody: [String: Any]? {
    switch self {
    case .create(_, let statusID):
      ["status_id": statusID]
    }
  }

  public var requires: APICapabilityRequirements? {
    FiltersV2Endpoint.filters.requires
  }
}
