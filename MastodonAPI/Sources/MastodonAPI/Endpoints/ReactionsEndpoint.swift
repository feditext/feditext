// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ReactionsEndpoint {
    /// Get reactions for a status.
    case status(id: Status.Id)
}

extension ReactionsEndpoint: Endpoint {
    public typealias ResultType = [Reaction]

    public var pathComponentsInContext: [String] {
        switch self {
        case let .status(id):
            return ["pleroma", "statuses", id, "reactions"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .status:
            return .get
        }
    }

    public var fallback: [Reaction]? { [] }

    public var requires: APICapabilityRequirements? {
        switch self {
        case .status:
            return [
                .pleroma: .assumeAvailable,
                .akkoma: .assumeAvailable
            ]
        }
    }

    public var notFound: EntityNotFound? {
        switch self {
        case .status(id: let id):
            return .status(id)
        }
    }
}
