// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum PollEndpoint {
  case poll(id: Poll.Id)
  case votes(id: Poll.Id, choices: [Int])
}

extension PollEndpoint: Endpoint {
  public typealias ResultType = Poll

  public var context: [String] {
    defaultContext + ["polls"]
  }

  public var pathComponentsInContext: [String] {
    switch self {
    case .poll(let id):
      return [id]
    case .votes(let id, _):
      return [id, "votes"]
    }
  }

  public var jsonBody: [String: Any]? {
    switch self {
    case .poll:
      return nil
    case .votes(_, let choices):
      return ["choices": choices]
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .poll:
      return .get
    case .votes:
      return .post
    }
  }

  public var requires: APICapabilityRequirements? {
    return .mastodonForks(.assumeAvailable) | [
      .fedibird: .assumeAvailable,
      .pleroma: .assumeAvailable,
      .akkoma: .assumeAvailable,
      .gotosocial: .assumeAvailable,
    ]
  }

  public var notFound: EntityNotFound? {
    switch self {
    case .poll(let id),
      .votes(let id, _):
      return .poll(id)
    }
  }
}
