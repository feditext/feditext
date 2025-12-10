// Copyright © 2023 Vyr Cossont. All rights reserved.

import Mastodon
import SwiftUI

extension Mastodon.List.RepliesPolicy {
  var localizedStringKey: LocalizedStringKey {
    switch self {
    case .followed:
      return "lists.edit-list.replies-policy.followed"
    case .list:
      return "lists.edit-list.replies-policy.list"
    case .none:
      return "lists.edit-list.replies-policy.none"
    case .unknown:
      return "lists.edit-list.replies-policy.unknown"
    }
  }
}
