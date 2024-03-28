// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum RelationshipEndpoint {
    case accountsFollow(id: Account.Id, showReblogs: Bool? = nil, notify: Bool? = nil)
    case accountsUnfollow(id: Account.Id)
    case accountsBlock(id: Account.Id)
    case accountsUnblock(id: Account.Id)
    case accountsMute(id: Account.Id, notifications: Bool = true, duration: Int = 0)
    case accountsUnmute(id: Account.Id)
    case accountsPin(id: Account.Id)
    case accountsUnpin(id: Account.Id)
    /// - https://docs.joinmastodon.org/methods/accounts/#note
    /// - https://api.pleroma.social/#operation/AccountController.note
    case note(String, id: Account.Id)
    case acceptFollowRequest(id: Account.Id)
    case rejectFollowRequest(id: Account.Id)
}

extension RelationshipEndpoint: Endpoint {
    public typealias ResultType = Relationship

    public var context: [String] {
        switch self {
        case .acceptFollowRequest, .rejectFollowRequest:
            return defaultContext + ["follow_requests"]
        default:
            return defaultContext + ["accounts"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .accountsFollow(id, _, _):
            return [id, "follow"]
        case let .accountsUnfollow(id):
            return [id, "unfollow"]
        case let .accountsBlock(id):
            return [id, "block"]
        case let .accountsUnblock(id):
            return [id, "unblock"]
        case let .accountsMute(id, _, _):
            return [id, "mute"]
        case let .accountsUnmute(id):
            return [id, "unmute"]
        case let .accountsPin(id):
            return [id, "pin"]
        case let .accountsUnpin(id):
            return [id, "unpin"]
        case let .note(_, id):
            return [id, "note"]
        case let .acceptFollowRequest(id):
            return [id, "authorize"]
        case let .rejectFollowRequest(id):
            return [id, "reject"]
        }
    }

    public var queryParameters: [URLQueryItem] {
        switch self {
        case let .accountsFollow(_, showReblogs, notify):
            var params = [URLQueryItem]()

            if let showReblogs = showReblogs {
                params.append(URLQueryItem(name: "reblogs", value: String(showReblogs)))
            }

            if let notify = notify {
                params.append(URLQueryItem(name: "notify", value: String(notify)))
            }

            return params
        default:
            return []
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .accountsMute(_, notifications, duration):
            return ["notifications": notifications, "duration": duration]
        case let .note(note, _):
            return ["comment": note]
        default:
            return nil
        }
    }

    public var method: HTTPMethod {
        .post
    }

    public var requires: APICapabilityRequirements? {
        switch self {
        case .note:
            return .mastodonForks("3.0.0") | [
                .fedibird: "0.1.0",
                .pleroma: .assumeAvailable,
                .akkoma: .assumeAvailable,
                .gotosocial: "0.11.0-0"
            ]
        case .accountsMute, .accountsUnmute:
            return AccountsEndpoint.mutes.requires
        default:
            return nil
        }
    }

    public var notFound: EntityNotFound? {
        switch self {
        case .accountsFollow(id: let id, _, _),
                .accountsUnfollow(id: let id),
                .accountsBlock(id: let id),
                .accountsUnblock(id: let id),
                .accountsMute(id: let id, _, _),
                .accountsUnmute(id: let id),
                .accountsPin(id: let id),
                .accountsUnpin(id: let id),
                .note(_, id: let id),
                .acceptFollowRequest(id: let id),
                .rejectFollowRequest(id: let id):
            return .account(id)
        }
    }
}
