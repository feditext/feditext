// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// https://docs.joinmastodon.org/methods/featured_tags/
public enum FeaturedTagsEndpoint {
    case featuredTags(id: Account.Id)
}

extension FeaturedTagsEndpoint: Endpoint {
    public typealias ResultType = [FeaturedTag]

    public var context: [String] {
        switch self {
        case .featuredTags:
            return defaultContext + ["accounts"]
        }

    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .featuredTags(id):
            return [id, "featured_tags"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .featuredTags:
            return .get
        }
    }

    public var requires: APICapabilityRequirements? {
        .mastodonForks("3.0.0") | [
            .fedibird: "0.1.0",
            .pleroma: .assumeAvailable,
            .akkoma: .assumeAvailable
        ]
    }

    public var fallback: [FeaturedTag]? { [] }
}
