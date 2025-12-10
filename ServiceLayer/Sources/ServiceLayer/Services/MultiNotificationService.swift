// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct MultiNotificationService {
  public let notificationServices: [NotificationService]
  public let accountServices: [AccountService]
  public let type: MastodonNotification.NotificationType
  public let date: Date

  private let environment: AppEnvironment
  private let mastodonAPIClient: MastodonAPIClient
  private let contentDatabase: ContentDatabase

  init(
    notificationServices: [NotificationService],
    notificationType: MastodonNotification.NotificationType,
    date: Date,
    environment: AppEnvironment,
    mastodonAPIClient: MastodonAPIClient,
    contentDatabase: ContentDatabase
  ) {
    self.notificationServices = notificationServices
    self.accountServices = notificationServices.map { notificationService in
      AccountService(
        account: notificationService.notification.account,
        environment: environment,
        mastodonAPIClient: mastodonAPIClient,
        contentDatabase: contentDatabase
      )
    }
    self.type = notificationType
    self.date = date
    self.environment = environment
    self.mastodonAPIClient = mastodonAPIClient
    self.contentDatabase = contentDatabase
  }

  public func accountListService() -> FixedAccountListService {
    let titleComponents: [String]?
    switch type {
    case .follow:
      titleComponents = ["account-list.title.followed-by"]
    case .favourite:
      titleComponents = ["account-list.title.favourited-by"]
    case .reblog:
      titleComponents = ["account-list.title.reblogged-by"]
    default:
      assertionFailure("Unexpected notification type: \(type)")
      titleComponents = nil
    }

    return FixedAccountListService(
      accounts: notificationServices.map { $0.notification.account },
      accountConfiguration: .withNote,
      environment: environment,
      mastodonAPIClient: mastodonAPIClient,
      contentDatabase: contentDatabase,
      titleComponents: titleComponents
    )
  }
}
