// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// https://docs.joinmastodon.org/methods/announcements/
public enum AnnouncementsEndpoint {
    case announcements
}

extension AnnouncementsEndpoint: Endpoint {
    public typealias ResultType = [Announcement]

    public var pathComponentsInContext: [String] {
        ["announcements"]
    }

    public var method: HTTPMethod {
        .get
    }

    public var requires: APICapabilityRequirements? {
        .mastodonForks("3.1.0") | [
            .fedibird: "0.1.0",
            .pleroma: .assumeAvailable,
            .akkoma: .assumeAvailable,
            .calckey: "14.0.0-0",
            .firefish: "1.0.0",
            .iceshrimp: "1.0.0"
        ]
    }

    public var fallback: [Announcement]? { [] }
}
