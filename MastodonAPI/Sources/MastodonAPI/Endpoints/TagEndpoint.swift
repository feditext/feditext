// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum TagEndpoint {
    case get(name: String)
    case follow(name: String)
    case unfollow(name: String)
}

extension TagEndpoint: Endpoint {
    public typealias ResultType = Tag

    public var context: [String] {
        defaultContext + ["tags"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .get(name):
            return [name]
        case let .follow(name):
            return [name, "follow"]
        case let .unfollow(name):
            return [name, "unfollow"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .get:
            return .get
        case .follow, .unfollow:
            return .post
        }
    }
}
