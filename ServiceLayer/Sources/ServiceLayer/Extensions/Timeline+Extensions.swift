// Copyright © 2020 Metabolist. All rights reserved.

import MastodonAPI

extension Timeline {
  var endpoint: StatusesEndpoint {
    switch self {
    case .home:
      return .timelinesHome
    case .local:
      return .timelinesPublic(local: true)
    case .federated:
      return .timelinesPublic(local: false)
    case .list(let list):
      return .timelinesList(id: list.id)
    case .tag(let tag):
      return .timelinesTag(tag)
    case .profile(let accountId, let profileCollection):
      let excludeReplies: Bool
      let excludeReblogs: Bool
      let onlyMedia: Bool

      switch profileCollection {
      case .statuses:
        excludeReplies = true
        excludeReblogs = true
        onlyMedia = false
      case .statusesAndReplies:
        excludeReplies = false
        excludeReblogs = true
        onlyMedia = false
      case .statusesAndBoosts:
        excludeReplies = false
        excludeReblogs = false
        onlyMedia = false
      case .media:
        excludeReplies = true
        excludeReblogs = true
        onlyMedia = true
      }

      return .accountsStatuses(
        id: accountId,
        excludeReplies: excludeReplies,
        excludeReblogs: excludeReblogs,
        onlyMedia: onlyMedia,
        pinned: false
      )
    case .favorites:
      return .favourites
    case .bookmarks:
      return .bookmarks
    }
  }
}
