// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StatusSourceEndpoint {
    /// https://docs.joinmastodon.org/methods/statuses/#source
    case source(id: Status.Id)
}

extension StatusSourceEndpoint: Endpoint {
    public typealias ResultType = StatusSource

    public var context: [String] {
        defaultContext + ["statuses"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .source(id):
            return [id, "source"]
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case .source:
            return nil
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .source:
            return .get
        }
    }
}
