// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum TagsEndpoint {
    /// https://docs.joinmastodon.org/methods/trends/#tags
    case trends(limit: Int? = nil, offset: Int? = nil)
    /// https://docs.joinmastodon.org/methods/trends/#tags (obsolete alias)
    case trendsLegacy(limit: Int? = nil, offset: Int? = nil)
    /// https://docs.joinmastodon.org/methods/followed_tags/#get
    case followed
}

extension TagsEndpoint: Endpoint {
    public typealias ResultType = [Tag]

    public var pathComponentsInContext: [String] {
        switch self {
        case .trends: return ["trends", "tags"]
        case .trendsLegacy: return ["trends"]
        case .followed: return ["followed_tags"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .trends, .trendsLegacy, .followed: return .get
        }
    }

    public var queryParameters: [URLQueryItem] {
        switch self {
        case let .trends(limit, offset), let .trendsLegacy(limit, offset):
            return queryParameters(limit, offset)
        case .followed:
            return []
        }
    }

    public var requires: APICapabilityRequirements? {
        switch self {
        case .trends:
            return .mastodonForks("3.5.0")
        case .trendsLegacy:
            return .mastodonForks("3.0.0") | [
                .fedibird: "0.1.0",
                .calckey: "14.0.0-0",
                .firefish: "1.0.0",
                .iceshrimp: "1.0.0"
            ]
        case .followed:
            return .mastodonForks("4.0.0") | [
                .pixelfed: .assumeAvailable,
                .gotosocial: "0.17.0-0",
            ]
        }
    }

    public var fallback: [Tag]? { [] }
}
