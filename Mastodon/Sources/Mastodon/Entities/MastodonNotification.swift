// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct MastodonNotification: Codable {
  public let id: Id
  public let type: NotificationType
  public let account: Account
  public let createdAt: Date
  public let status: Status?
  public let report: Report?

  public init(
    id: String,
    type: MastodonNotification.NotificationType,
    account: Account,
    createdAt: Date,
    status: Status?,
    report: Report?
  ) {
    self.id = id
    self.type = type
    self.account = account
    self.createdAt = createdAt
    self.status = status
    self.report = report
  }
}

extension MastodonNotification: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension MastodonNotification {
  public typealias Id = String

  // TODO: (Vyr) notifications: investigate additional Glitch, Firefish, Akkoma types, including reactions
  /// https://docs.joinmastodon.org/entities/Notification/#type
  /// https://docs.akkoma.dev/stable/development/API/differences_in_mastoapi_responses/#notifications
  public enum NotificationType: String, Codable, Unknowable {
    case follow
    case mention
    case reblog
    case favourite
    case poll
    case followRequest = "follow_request"
    case status
    case update
    case adminSignup = "admin.sign_up"
    case adminReport = "admin.report"
    case unknown

    public static var unknownCase: Self { .unknown }
  }
}

extension MastodonNotification.NotificationType: Identifiable {
  public var id: Self { self }
}
