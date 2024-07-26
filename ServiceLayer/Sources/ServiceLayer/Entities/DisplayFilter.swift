// Copyright © 2023 Vyr Cossont. All rights reserved.

import DB

/// Used for post-fetch filtering of collection items, currently statuses.
public struct DisplayFilter: Codable {
    public var showBots: Bool
    public var showReblogs: Bool
    public var showReplies: Bool

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
        case let .status(status, _, _, _):
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
}
