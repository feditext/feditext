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
    case .accountsFollow(let id, _, _):
      return [id, "follow"]
    case .accountsUnfollow(let id):
      return [id, "unfollow"]
    case .accountsBlock(let id):
      return [id, "block"]
    case .accountsUnblock(let id):
      return [id, "unblock"]
    case .accountsMute(let id, _, _):
      return [id, "mute"]
    case .accountsUnmute(let id):
      return [id, "unmute"]
    case .accountsPin(let id):
      return [id, "pin"]
    case .accountsUnpin(let id):
      return [id, "unpin"]
    case .note(_, let id):
      return [id, "note"]
    case .acceptFollowRequest(let id):
      return [id, "authorize"]
    case .rejectFollowRequest(let id):
      return [id, "reject"]
    }
  }

  public var queryParameters: [URLQueryItem] {
    switch self {
    case .accountsFollow(_, let showReblogs, let notify):
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
    case .accountsMute(_, let notifications, let duration):
      return ["notifications": notifications, "duration": duration]
    case .note(let note, _):
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
        .gotosocial: "0.11.0-0",
      ]
    case .accountsMute, .accountsUnmute:
      return AccountsEndpoint.mutes.requires
    default:
      return nil
    }
  }

  public var notFound: EntityNotFound? {
    switch self {
    case .accountsFollow(let id, _, _),
      .accountsUnfollow(let id),
      .accountsBlock(let id),
      .accountsUnblock(let id),
      .accountsMute(let id, _, _),
      .accountsUnmute(let id),
      .accountsPin(let id),
      .accountsUnpin(let id),
      .note(_, let id),
      .acceptFollowRequest(let id),
      .rejectFollowRequest(let id):
      return .account(id)
    }
  }
}
