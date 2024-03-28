// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StatusSourceEndpoint {
    /// https://docs.joinmastodon.org/methods/statuses/#source
    /// https://api.pleroma.social/#operation/StatusController.show_source
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

    public var requires: APICapabilityRequirements? {
        .mastodonForks("3.5.0") | [
            .pleroma: .assumeAvailable,
            .akkoma: .assumeAvailable
        ]
    }

    public var notFound: EntityNotFound? {
        switch self {
        case .source(id: let id):
            return .status(id)
        }
    }
}
