// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Mastodon

/// When looking at a thread, we can expand or collapse all CWs.
public final class ContextTimelineActionViewModel: ObservableObject {
  @Published public var expandAll: ExpandAllState = .expand

  public func toggle() {
    switch expandAll {
    case .expand:
      expandAll = .expanding
    case .collapse:
      expandAll = .collapsing
    case .collapsing, .expanding:
      return
    }
  }
}
