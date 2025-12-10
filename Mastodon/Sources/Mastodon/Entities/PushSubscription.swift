// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct PushSubscription: Codable {
  public struct Alerts: Codable, Hashable {
    public var follow: Bool
    public var favourite: Bool
    public var reblog: Bool
    public var mention: Bool
    @DecodableDefault.True public var followRequest: Bool
    @DecodableDefault.True public var poll: Bool
    @DecodableDefault.True public var status: Bool
    @DecodableDefault.True public var update: Bool
    @DecodableDefault.True public var adminSignup: Bool
    @DecodableDefault.True public var adminReport: Bool

    // swiftlint:disable:next nesting
    enum CodingKeys: String, CodingKey {
      case follow
      case favourite
      case reblog
      case mention
      case followRequest
      case poll
      case status
      case update
      /// Note: this *has* to be wrong because of an interaction with `KeyDecodingStrategy.convertFromSnakeCase`,
      /// which is used by `MastodonDecoder`. The actual key on the wire is `admin.sign_up`.
      case adminSignup = "admin.signUp"
      case adminReport = "admin.report"
    }
  }

  public enum Policy: String, Codable, Identifiable, Unknowable {
    case all
    case followed
    case follower
    case none
    case unknown

    public var id: Self { self }

    public static var unknownCase: Self { .unknown }
  }

  public let endpoint: UnicodeURL
  public let alerts: Alerts
  public let policy: Policy
  public let serverKey: String
}

extension PushSubscription.Alerts {
  public static let initial: Self = Self(
    follow: true,
    favourite: true,
    reblog: true,
    mention: true,
    followRequest: DecodableDefault.True(),
    poll: DecodableDefault.True(),
    status: DecodableDefault.True(),
    update: DecodableDefault.True(),
    adminSignup: DecodableDefault.True(),
    adminReport: DecodableDefault.True()
  )
}
