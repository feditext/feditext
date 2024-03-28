// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// https://docs.joinmastodon.org/methods/tags/
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

    public var requires: APICapabilityRequirements? {
        switch self {
        case .get, .follow, .unfollow:
            return TagsEndpoint.followed.requires
        }
    }

    /// Mastodon claims never to 404 for these methods, but we have these in case other implementations do.
    public var notFound: EntityNotFound? {
        switch self {
        case .get(let name),
                .follow(let name),
                .unfollow(let name):
            return .tag(name)
        }
    }
}
