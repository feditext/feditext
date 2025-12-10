// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// https://docs.joinmastodon.org/methods/push/
public enum PushSubscriptionEndpoint {
  case create(
    endpoint: URL,
    publicKey: String,
    auth: String,
    alerts: PushSubscription.Alerts,
    policy: PushSubscription.Policy
  )
  case read
  case update(
    alerts: PushSubscription.Alerts,
    policy: PushSubscription.Policy
  )
  case delete
}

extension PushSubscriptionEndpoint: Endpoint {
  public typealias ResultType = PushSubscription

  public var context: [String] {
    defaultContext + ["push", "subscription"]
  }

  public var pathComponentsInContext: [String] { [] }

  public var method: HTTPMethod {
    switch self {
    case .create: return .post
    case .read: return .get
    case .update: return .put
    case .delete: return .delete
    }
  }

  public var jsonBody: [String: Any]? {
    switch self {
    case .create(let endpoint, let publicKey, let auth, let alerts, let policy):
      return [
        "subscription": [
          "endpoint": endpoint.absoluteString,
          "keys": [
            "p256dh": publicKey,
            "auth": auth,
          ],
        ] as [String: Any],
        "data": [
          "alerts": [
            "follow": alerts.follow,
            "favourite": alerts.favourite,
            "reblog": alerts.reblog,
            "mention": alerts.mention,
            "follow_request": alerts.followRequest,
            "poll": alerts.poll,
            "status": alerts.status,
            "update": alerts.update,
            "admin.sign_up": alerts.adminSignup,
            "admin.report": alerts.adminReport,
          ],
          "policy": policy.rawValue,
        ] as [String: Any],
      ]
    case .update(let alerts, let policy):
      return [
        "data": [
          "alerts": [
            "follow": alerts.follow,
            "favourite": alerts.favourite,
            "reblog": alerts.reblog,
            "mention": alerts.mention,
            "follow_request": alerts.followRequest,
            "poll": alerts.poll,
            "status": alerts.status,
            "update": alerts.update,
            "admin.sign_up": alerts.adminSignup,
            "admin.report": alerts.adminReport,
          ],
          "policy": policy.rawValue,
        ] as [String: Any]
      ]
    default: return nil
    }
  }
}
