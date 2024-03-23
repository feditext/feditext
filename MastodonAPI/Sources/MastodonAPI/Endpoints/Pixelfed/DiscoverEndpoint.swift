// Copyright © 2024 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

public extension Pixelfed {
    enum DiscoverEndpoint {
        case posts
    }
}

extension Pixelfed.DiscoverEndpoint: Endpoint {
    public typealias ResultType = Pixelfed.Discover

    public var pathComponentsInContext: [String] {
        switch self {
        case .posts:
            return ["discover", "posts"]
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .posts:
            return .get
        }
    }

    public var fallback: Pixelfed.Discover? { .init(posts: []) }

    public var requires: APICapabilityRequirements? { [.pixelfed: .assumeAvailable] }
}
