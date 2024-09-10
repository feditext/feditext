// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ListEndpoint {
    /// https://docs.joinmastodon.org/methods/lists/#create
    case create(title: String, repliesPolicy: List.RepliesPolicy?, exclusive: Bool?)
    /// https://docs.joinmastodon.org/methods/lists/#update
    case update(id: List.Id, title: String, repliesPolicy: List.RepliesPolicy?, exclusive: Bool?)
}

extension ListEndpoint: Endpoint {
    public typealias ResultType = List

    public var context: [String] {
        defaultContext + ["lists"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .create:
            return []
        case let .update(id, _, _, _):
            return [id]
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .create(title, repliesPolicy, exclusive),
            let .update(_, title, repliesPolicy, exclusive):

            var body: [String: Any] = ["title": title]

            if let repliesPolicy = repliesPolicy {
                body["replies_policy"] = repliesPolicy.rawValue
            }

            if let exclusive = exclusive {
                body["exclusive"] = exclusive
            }

            return body
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        case .update:
            return .put
        }
    }

    public var requires: APICapabilityRequirements? {
        switch self {
        case .create(title: _, repliesPolicy: nil, exclusive: nil),
                .update(id: _, title: _, repliesPolicy: nil, exclusive: nil):
            return ListsEndpoint.lists.requires
        case .create(title: _, repliesPolicy: _, exclusive: nil),
                .update(id: _, title: _, repliesPolicy: _, exclusive: nil):
            return .mastodonForks("3.3.0") | [
                .fedibird: "0.1.0",
                .gotosocial: "0.10.0-0",
            ]
        case .create(title: _, repliesPolicy: nil, exclusive: _),
                .update(id: _, title: _, repliesPolicy: nil, exclusive: _):
            return [
                .mastodon: "4.2.0",
                .glitch: "4.2.0",
                /// https://github.com/hometown-fork/hometown/releases/tag/v1.0.0%2B2.9.3
                .hometown: "2.9.3",
                .gotosocial: "0.17.0-0",
            ]
        case .create, .update:
            return [
                .mastodon: "4.2.0",
                .glitch: "4.2.0",
                .hometown: "3.3.0",
                .gotosocial: "0.17.0-0",
            ]
        }
    }

    public var notFound: EntityNotFound? {
        switch self {
        case .create:
            return nil

        case .update(id: let id, _, _, _):
            return .list(id)
        }
    }
}
