// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// https://docs.joinmastodon.org/methods/lists/
public enum ListsEndpoint {
    case lists
    case listsWithAccount(id: Account.Id)
}

extension ListsEndpoint: Endpoint {
    public typealias ResultType = [List]

    public var context: [String] {
        switch self {
        case .lists:
            return defaultContext
        case .listsWithAccount:
            return defaultContext + ["accounts"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .lists:
            return ["lists"]
        case let .listsWithAccount(id):
            return [id, "lists"]
        }
    }

    public var method: HTTPMethod {
        .get
    }

    public var requires: APICapabilityRequirements? {
        .mastodonForks("2.1.0") | [
            .fedibird: "0.1.0",
            .pleroma: .assumeAvailable,
            .akkoma: .assumeAvailable,
            .gotosocial: "0.10.0-0",
        ]
        // Stubbed in Pixelfed 0.11.
    }

    public var fallback: [List]? { [] }
}
