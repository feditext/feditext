// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// https://docs.joinmastodon.org/methods/markers/
public enum MarkersEndpoint {
    case get(Set<Marker.Timeline>)
    case post([Marker.Timeline: String])
}

extension MarkersEndpoint: Endpoint {
    public typealias ResultType = [String: Marker]

    public var pathComponentsInContext: [String] {
        ["markers"]
    }

    public var queryParameters: [URLQueryItem] {
        switch self {
        case let .get(timelines):
            return Array(timelines).map { URLQueryItem(name: "timeline[]", value: $0.rawValue) }
        case .post:
            return []
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case .get:
            return nil
        case let .post(lastReadIds):
            return Dictionary(uniqueKeysWithValues: lastReadIds.map { ($0.rawValue, ["last_read_id": $1]) })
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .get:
            return .get
        case .post:
            return .post
        }
    }

    public var requires: APICapabilityRequirements? {
        .mastodonForks("3.0.0") | [
            .fedibird: "0.1.0",
            .pleroma: .assumeAvailable,
            .akkoma: .assumeAvailable,
            .gotosocial: "0.11.0-0"
        ]
    }

    public var fallback: [String: Marker]? { [:] }
}
