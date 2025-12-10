// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public enum CollectionItem: Hashable {
  case status(
    _ status: Status,
    _ config: StatusConfiguration,
    authorRelationship: Relationship?,
    rebloggerRelationship: Relationship?
  )
  case loadMore(LoadMore)
  case account(Account, AccountConfiguration, Relationship?, [Account], Suggestion.Source?)
  case notification(MastodonNotification, [Rule], StatusConfiguration?)
  case multiNotification([MastodonNotification], MastodonNotification.NotificationType, Date, Status?)
  case conversation(Conversation)
  case tag(Tag)
  case link(Card)
  case announcement(Announcement)
  case moreResults(MoreResults)
}

extension CollectionItem {
  public typealias Id = String

  public struct StatusConfiguration: Hashable {
    public let showContentToggled: Bool
    public let showAttachmentsToggled: Bool
    public let showFilteredToggled: Bool
    public let isContextParent: Bool
    public let isPinned: Bool
    public let isReplyInContext: Bool
    public let isReplyOutOfContext: Bool
    public let hasReplyFollowing: Bool

    init(
      showContentToggled: Bool,
      showAttachmentsToggled: Bool,
      showFilteredToggled: Bool,
      isContextParent: Bool = false,
      isPinned: Bool = false,
      isReplyInContext: Bool = false,
      isReplyOutOfContext: Bool = false,
      hasReplyFollowing: Bool = false
    ) {
      self.showContentToggled = showContentToggled
      self.showAttachmentsToggled = showAttachmentsToggled
      self.showFilteredToggled = showFilteredToggled
      self.isContextParent = isContextParent
      self.isPinned = isPinned
      self.isReplyInContext = isReplyInContext
      self.isReplyOutOfContext = isReplyOutOfContext
      self.hasReplyFollowing = hasReplyFollowing
    }
  }

  public enum AccountConfiguration: Hashable {
    case withNote
    case withoutNote
    case followRequest
    case followSuggestion
    case mute
    case block
  }

  public var itemId: Id? {
    switch self {
    case .status(let status, _, _, _):
      return status.id
    case .loadMore:
      return nil
    case .account(let account, _, _, _, _):
      return account.id
    case .notification(let notification, _, _):
      return notification.id
    case .multiNotification:
      return nil
    case .conversation(let conversation):
      return conversation.id
    case .tag(let tag):
      return tag.name
    case .link(let card):
      return card.url.raw
    case .announcement(let announcement):
      return announcement.id
    case .moreResults:
      return nil
    }
  }

  public var statusId: Status.Id? {
    switch self {
    case .status(let status, _, _, _):
      return status.id
    case .loadMore:
      return nil
    case .account:
      return nil
    case .notification(let notification, _, _):
      return notification.status?.id
    case .multiNotification(_, _, _, let status):
      return status?.id
    case .conversation(let conversation):
      return conversation.lastStatus?.id
    case .tag:
      return nil
    case .link:
      return nil
    case .announcement:
      return nil
    case .moreResults:
      return nil
    }
  }
}

extension CollectionItem.StatusConfiguration {
  public static let `default` = Self(
    showContentToggled: false,
    showAttachmentsToggled: false,
    showFilteredToggled: false
  )

  public func reply() -> Self {
    Self(
      showContentToggled: showContentToggled,
      showAttachmentsToggled: showAttachmentsToggled,
      showFilteredToggled: showFilteredToggled,
      isContextParent: false,
      isPinned: false,
      isReplyInContext: false,
      hasReplyFollowing: true
    )
  }
}
