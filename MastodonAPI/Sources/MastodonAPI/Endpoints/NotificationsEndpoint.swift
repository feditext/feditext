// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum NotificationsEndpoint {
  case notifications(excludeTypes: Set<MastodonNotification.NotificationType>)
}

extension NotificationsEndpoint: Endpoint {
  public typealias ResultType = [MastodonNotification]

  public var pathComponentsInContext: [String] {
    ["notifications"]
  }

  public var queryParameters: [URLQueryItem] {
    switch self {
    case .notifications(let excludeTypes):
      return Array(excludeTypes).map { URLQueryItem(name: "exclude_types[]", value: $0.rawValue) }
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .notifications:
      return .get
    }
  }

  public var fallback: [MastodonNotification]? { [] }
}
