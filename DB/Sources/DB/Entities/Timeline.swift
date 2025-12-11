// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public enum Timeline: Hashable {
  case home
  case local
  case federated
  case list(List)
  case tag(Tag.Name)
  case profile(accountId: Account.Id, profileCollection: ProfileCollection)
  case favorites
  case bookmarks
}

extension Timeline {
  public typealias Id = String

  public static let unauthenticatedDefaults: [Timeline] = [.local, .federated]
  public static let authenticatedDefaults: [Timeline] = [.home, .local, .federated]

  public var filterContext: Filter.Context? {
    switch self {
    case .home, .list:
      return .home
    case .local, .federated, .tag:
      return .public
    case .profile:
      return .account
    default:
      return nil
    }
  }

  public var ordered: Bool {
    switch self {
    case .favorites, .bookmarks:
      return true
    default:
      return false
    }
  }
}

extension Timeline: Identifiable {
  public var id: Id {
    switch self {
    case .home:
      return "home"
    case .local:
      return "local"
    case .federated:
      return "federated"
    case .list(let list):
      return "list-".appending(list.id)
    case .tag(let tag):
      return "tag-".appending(tag).lowercased()
    case .profile(let accountId, let profileCollection):
      return "profile-\(accountId)-\(profileCollection)"
    case .favorites:
      return "favorites"
    case .bookmarks:
      return "bookmarks"
    }
  }
}

extension Timeline {
  init?(record: TimelineRecord) {
    switch record.id {
    case Timeline.home.id:
      self = .home
    case Timeline.local.id:
      self = .local
    case Timeline.federated.id:
      self = .federated
    case Timeline.favorites.id:
      self = .favorites
    case Timeline.bookmarks.id:
      self = .bookmarks

    default:
      if let id = record.listId,
        let title = record.listTitle
      {
        self = .list(
          List(
            id: id,
            title: title,
            repliesPolicy: record.listRepliesPolicy,
            exclusive: record.listExclusive
          )
        )
      } else if let tag = record.tag {
        self = .tag(tag)
      } else if let accountId = record.accountId,
        let profileCollection = record.profileCollection
      {
        self = .profile(
          accountId: accountId,
          profileCollection: profileCollection
        )
      } else {
        return nil
      }
    }
  }

  func ephemeralityId(id: Identity.Id) -> String? {
    switch self {
    case .tag, .favorites, .bookmarks:
      return "\(id)-\(self.id)"
    default:
      return nil
    }
  }
}
