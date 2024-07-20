// Copyright © 2024 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

// TODO: (Vyr) fill out other filters v2 endpoints
public enum FiltersV2Endpoint {
    case filters
}

extension FiltersV2Endpoint: Endpoint {
    public typealias ResultType = [FilterV2]

    public var APIVersion: String { "v2" }

    public var context: [String] {
        defaultContext + ["filters"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .filters:
            return []
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .filters:
            return .get
        }
    }

    public var requires: APICapabilityRequirements? {
        .mastodonForks("4.0.0") | [
            .gotosocial: "0.16.0-0",
        ]
    }

    public var fallback: [FilterV2]? { [] }
}
