// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import ServiceLayer

extension UserNotificationClient {
  public static let mock = UserNotificationClient(
    getNotificationSettings: { _ in },
    requestAuthorization: { _, _ in },
    add: { _, completion in completion?(nil) },
    removeDeliveredNotifications: { _ in },
    delegateEvents: Empty(completeImmediately: false).eraseToAnyPublisher())
}
