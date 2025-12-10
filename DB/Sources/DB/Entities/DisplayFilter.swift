// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Used for post-fetch filtering of collection items, currently statuses.
/// - Note: doesn't use an ``OptionSet`` because display filters might have params in the future.
public struct DisplayFilter: Codable, Hashable {
  public var showBots: Bool
  public var showReblogs: Bool
  public var showReplies: Bool

  /// If default arguments are used, the filter allows any item.
  public init(showBots: Bool = true, showReblogs: Bool = true, showReplies: Bool = true) {
    self.showBots = showBots
    self.showReblogs = showReblogs
    self.showReplies = showReplies
  }

  /// Is this filter actually rejecting anything?
  public var filtering: Bool { !(showBots && showReblogs && showReplies) }

  /// Decide whether or not to show the item.
  public func allow(_ item: CollectionItem) -> Bool {
    switch item {
    case .status(let status, _, _, _):
      if status.account.bot && !showBots {
        return false
      }
      if status.reblog != nil && !showReblogs {
        return false
      }
      if status.inReplyToId != nil && !showReplies {
        return false
      }
      return true
    default:
      return true
    }
  }

  /// No-op filter.
  public static let showAll: Self = .init()
}

extension Timeline {
  /// Does it make sense for this timeline to have a display filter?
  var hasDisplayFilter: Bool {
    switch self {
    case .home,
      .local,
      .federated:
      true
    case .list,
      .tag,
      .profile,
      .favorites,
      .bookmarks:
      // TODO: (Vyr) it might make sense to add this to lists and tags in the future,
      //  but we don't have UI for it yet.
      false
    }
  }
}
