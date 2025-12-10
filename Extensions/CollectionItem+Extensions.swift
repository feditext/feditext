// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

extension CollectionItem {
  static let cellClasses = [
    StatusTableViewCell.self,
    AccountTableViewCell.self,
    LoadMoreTableViewCell.self,
    NotificationTableViewCell.self,
    MultiNotificationTableViewCell.self,
    ConversationTableViewCell.self,
    TagTableViewCell.self,
    CardTableViewCell.self,
    AnnouncementTableViewCell.self,
    SeparatorConfiguredTableViewCell.self,
  ]

  var cellClass: AnyClass {
    switch self {
    case .status:
      return StatusTableViewCell.self
    case .account:
      return AccountTableViewCell.self
    case .loadMore:
      return LoadMoreTableViewCell.self
    case .notification(_, _, let statusConfiguration):
      return statusConfiguration == nil ? NotificationTableViewCell.self : StatusTableViewCell.self
    case .multiNotification:
      return MultiNotificationTableViewCell.self
    case .conversation:
      return ConversationTableViewCell.self
    case .tag:
      return TagTableViewCell.self
    case .link:
      return CardTableViewCell.self
    case .announcement:
      return AnnouncementTableViewCell.self
    case .moreResults:
      return SeparatorConfiguredTableViewCell.self
    }
  }

  func estimatedHeight(width: CGFloat, identityContext: IdentityContext) -> CGFloat {
    switch self {
    case .status(let status, let configuration, _, _):
      return StatusView.estimatedHeight(
        width: width,
        identityContext: identityContext,
        status: status,
        configuration: configuration
      )
    case .account(let account, let configuration, let relationship, let familiarFollowers, let suggestionSource):
      return AccountView.estimatedHeight(
        width: width,
        account: account,
        configuration: configuration,
        relationship: relationship,
        familiarFollowers: familiarFollowers,
        suggestionSource: suggestionSource
      )
    case .loadMore:
      return LoadMoreView.estimatedHeight
    case .notification(let notification, let rules, let configuration):
      return NotificationView.estimatedHeight(
        width: width,
        identityContext: identityContext,
        notification: notification,
        rules: rules,
        configuration: configuration
      )
    case .multiNotification(let notifications, _, _, let status):
      return MultiNotificationView.estimatedHeight(
        width: width,
        identityContext: identityContext,
        notifications: notifications,
        status: status
      )
    case .conversation(let conversation):
      return ConversationView.estimatedHeight(
        width: width,
        identityContext: identityContext,
        conversation: conversation)
    case .tag(let tag):
      return TagView.estimatedHeight(width: width, tag: tag)
    case .link:
      return UITableView.automaticDimension
    case .announcement(let announcement):
      return AnnouncementView.estimatedHeight(width: width, announcement: announcement)
    case .moreResults:
      return UITableView.automaticDimension
    }
  }

  func mediaPrefetchURLs(identityContext: IdentityContext) -> Set<URL> {
    switch self {
    case .status(let status, _, _, _):
      return status.mediaPrefetchURLs(identityContext: identityContext)
    case .account(let account, _, _, _, _):
      return account.mediaPrefetchURLs(identityContext: identityContext)
    case .notification(let notification, _, _):
      var urls = notification.account.mediaPrefetchURLs(identityContext: identityContext)

      if let status = notification.status {
        urls.formUnion(status.mediaPrefetchURLs(identityContext: identityContext))
      }

      return urls
    case .conversation(let conversation):
      return conversation.accounts.reduce(Set<URL>()) {
        $0.union($1.mediaPrefetchURLs(identityContext: identityContext))
      }
    default:
      return []
    }
  }
}

extension Account {
  fileprivate func mediaPrefetchURLs(identityContext: IdentityContext) -> Set<URL> {
    var urls = Set(
      emojis.compactMap {
        (identityContext.appPreferences.animateCustomEmojis ? $0.url : $0.staticUrl).url
      })

    if identityContext.appPreferences.animateAvatars == .everywhere {
      if let url = avatar.url {
        urls.insert(url)
      }
    } else {
      if let url = unifiedAvatarStatic.url {
        urls.insert(url)
      }
    }

    return urls
  }
}

extension Status {
  fileprivate func mediaPrefetchURLs(identityContext: IdentityContext) -> Set<URL> {
    displayStatus.account.mediaPrefetchURLs(identityContext: identityContext)
      .union(displayStatus.mediaAttachments.compactMap(\.previewUrl?.url))
      .union(
        displayStatus.emojis.compactMap {
          (identityContext.appPreferences.animateCustomEmojis ? $0.url : $0.staticUrl).url
        })
  }
}
