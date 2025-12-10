// Copyright © 2023 Vyr Cossont. All rights reserved.

import Mastodon
import SwiftUI

extension Suggestion.Source {
  var localizedStringKey: String {
    switch self {
    case .staff:
      return "explore.suggested-accounts.source.staff"
    case .pastInteractions:
      return "explore.suggested-accounts.source.past-interactions"
    case .global:
      return "explore.suggested-accounts.source.global"
    case .unknown:
      return "explore.suggested-accounts.source.unknown"
    }
  }

  var systemImageName: String {
    switch self {
    case .staff:
      return "pin.fill"
    case .pastInteractions:
      return "bubble.left.and.bubble.right.fill"
    case .global:
      return "crown.fill"
    case .unknown:
      return "questionmark"
    }
  }
}
