// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ConversationsEndpoint {
    case conversations
}

extension ConversationsEndpoint: Endpoint {
    public typealias ResultType = [Conversation]

    public var pathComponentsInContext: [String] {
        ["conversations"]
    }

    public var method: HTTPMethod { .get }

    public var requires: APICapabilityRequirements? {
        .mastodonForks("3.0.0") | [
            .fedibird: "0.1.0",
            .pleroma: .assumeAvailable,
            .akkoma: .assumeAvailable,
            .calckey: "14.0.0-0",
            .firefish: "1.0.0",
            .iceshrimp: "1.0.0",
            .pixelfed: .assumeAvailable,
        ]
    }

    public var fallback: [Conversation]? { [] }
}
