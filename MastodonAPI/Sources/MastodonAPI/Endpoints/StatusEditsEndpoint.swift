// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StatusEditsEndpoint {
  /// https://docs.joinmastodon.org/methods/statuses/#history
  case history(id: Status.Id)
}

extension StatusEditsEndpoint: Endpoint {
  public typealias ResultType = [StatusEdit]

  public var context: [String] {
    defaultContext + ["statuses"]
  }

  public var pathComponentsInContext: [String] {
    switch self {
    case .history(let id):
      return [id, "history"]
    }
  }

  public var jsonBody: [String: Any]? {
    switch self {
    case .history:
      return nil
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .history:
      return .get
    }
  }

  public var requires: APICapabilityRequirements? {
    .mastodonForks("3.5.0") | [
      .pleroma: .assumeAvailable,
      .akkoma: .assumeAvailable,
      .pixelfed: .assumeAvailable,
      .gotosocial: "0.18.0-0",
    ]
  }

  public var fallback: [StatusEdit]? { [] }

  public var notFound: EntityNotFound? {
    switch self {
    case .history(let id):
      return .status(id)
    }
  }
}
