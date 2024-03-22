// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StringsEndpoint {
    /// https://docs.joinmastodon.org/methods/domain_blocks/#get
    case domainBlocks
}

extension StringsEndpoint: Endpoint {
    public typealias ResultType = [String]

    public var pathComponentsInContext: [String] {
        switch self {
        case .domainBlocks:
            return ["domain_blocks"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .domainBlocks:
            return .get
        }
    }

    public var requires: APICapabilityRequirements? {
        switch self {
        case .domainBlocks:
            return .mastodonForks("1.4.0") | [
                .fedibird: "0.1.0",
                .pleroma: .assumeAvailable,
                .akkoma: .assumeAvailable,
                .pixelfed: .assumeAvailable,
            ]
        }
    }

    public var fallback: [String]? { [] }
}
