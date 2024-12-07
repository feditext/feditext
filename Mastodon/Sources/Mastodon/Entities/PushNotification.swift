// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

/// Payload for a Web Push notification, distinct from an API push notification.
public struct PushNotification: Codable {
    public let accessToken: String
    public let body: String
    public let title: String
    public let icon: UnicodeURL
    @PushNotificationID public var notificationId: String
    public let notificationType: MastodonNotification.NotificationType
    public let preferredLocale: String
  
    public init(
        accessToken: String,
        body: String,
        title: String,
        icon: UnicodeURL,
        notificationId: String,
        notificationType: MastodonNotification.NotificationType,
        preferredLocale: String
    ) {
        self.accessToken = accessToken
        self.body = body
        self.title = title
        self.icon = icon
        self.notificationId = notificationId
        self.notificationType = notificationType
        self.preferredLocale = preferredLocale
    }
}
