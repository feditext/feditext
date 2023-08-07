// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StatusesEndpoint {
    /// https://docs.joinmastodon.org/methods/timelines/#public
    case timelinesPublic(local: Bool)
    /// https://docs.joinmastodon.org/methods/timelines/#tag
    case timelinesTag(String)
    /// https://docs.joinmastodon.org/methods/timelines/#home
    case timelinesHome
    /// https://docs.joinmastodon.org/methods/timelines/#list
    case timelinesList(id: List.Id)
    case accountsStatuses(id: Account.Id, excludeReplies: Bool, excludeReblogs: Bool, onlyMedia: Bool, pinned: Bool)
    case favourites
    case bookmarks
    /// https://docs.joinmastodon.org/methods/trends/#statuses
    case trends(limit: Int? = nil, offset: Int? = nil)
}

extension StatusesEndpoint: Endpoint {
    public typealias ResultType = [Status]

    public var context: [String] {
        switch self {
        case .timelinesPublic, .timelinesTag, .timelinesHome, .timelinesList:
            return defaultContext + ["timelines"]
        case .accountsStatuses:
            return defaultContext + ["accounts"]
        default:
            return defaultContext
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .timelinesPublic:
            return ["public"]
        case let .timelinesTag(tag):
            return ["tag", tag]
        case .timelinesHome:
            return ["home"]
        case let .timelinesList(id):
            return ["list", id]
        case let .accountsStatuses(id, _, _, _, _):
            return [id, "statuses"]
        case .favourites:
            return ["favourites"]
        case .bookmarks:
            return ["bookmarks"]
        case .trends:
            return ["trends", "statuses"]
        }
    }

    public var queryParameters: [URLQueryItem] {
        switch self {
        case let .timelinesPublic(local):
            return [URLQueryItem(name: "local", value: String(local))]
        case let .accountsStatuses(_, excludeReplies, excludeReblogs, onlyMedia, pinned):
            // Send boolean params only if true.
            // Firefish and Hajkey currently (2023-08-01) can't handle the pinned parameter's presence,
            // and will return an empty list even if pinned=false was requested. See Feditext bug #152.
            var items = [URLQueryItem]()
            if excludeReplies {
                items.append(URLQueryItem(name: "exclude_replies", value: String(excludeReplies)))
            }
            if excludeReblogs {
                items.append(URLQueryItem(name: "exclude_reblogs", value: String(excludeReblogs)))
            }
            if onlyMedia {
                items.append(URLQueryItem(name: "only_media", value: String(onlyMedia)))
            }
            if pinned {
                items.append(URLQueryItem(name: "pinned", value: String(pinned)))
            }
            return items
        case let .trends(limit, offset):
            return queryParameters(limit, offset)
        default:
            return []
        }
    }

    public var method: HTTPMethod { .get }

    public var requires: APICapabilityRequirements? {
        switch self {
        case .trends:
            return .mastodonForks("3.5.0") | [
                .calckey: "14.0.0-0",
                .firefish: "1.0.0"
            ]
        case .timelinesTag:
            return .mastodonForks(.assumeAvailable) | [
                .pleroma: .assumeAvailable,
                .akkoma: .assumeAvailable,
                .calckey: "14.0.0-0",
                .firefish: "1.0.0",
                .gotosocial: "0.11.0-0"
            ]
        case .timelinesList:
            return .mastodonForks(.assumeAvailable) | [
                .pleroma: .assumeAvailable,
                .akkoma: .assumeAvailable,
                .gotosocial: "0.10.0-0",
                .calckey: "14.0.0-0",
                .firefish: "1.0.0"
            ]
        default:
            return nil
        }
    }

    public var fallback: [Status]? { [] }
}
