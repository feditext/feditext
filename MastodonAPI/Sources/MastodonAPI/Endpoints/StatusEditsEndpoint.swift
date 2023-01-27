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
        case let .history(id):
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
}
