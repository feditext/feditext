// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// https://docs.joinmastodon.org/methods/suggestions/
public enum SuggestionsEndpoint {
    case suggestions(limit: Int? = nil)
}

extension SuggestionsEndpoint: Endpoint {
    public typealias ResultType = [Suggestion]
    public var pathComponentsInContext: [String] { ["suggestions"] }
    public var method: HTTPMethod { .get }
    public var APIVersion: String { "v2" }

    public var queryParameters: [URLQueryItem] {
        switch self {
        case let .suggestions(limit):
            return queryParameters(limit, nil)
        }
    }

    public var requires: APICapabilityRequirements? {
        .mastodonForks("3.4.0") | [
            .fedibird: "0.1.0",
            .calckey: "14.0.0-0",
            .firefish: "1.0.0",
            .iceshrimp: "1.0.0"
        ]
    }

    public var fallback: [Suggestion]? { [] }
}
