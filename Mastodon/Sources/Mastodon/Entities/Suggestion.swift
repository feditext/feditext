// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// A suggested account to follow, with attached reason.
/// https://docs.joinmastodon.org/entities/Suggestion/
public struct Suggestion: Codable, Hashable {
  /// https://docs.joinmastodon.org/entities/Suggestion/#source
  public enum Source: String, Codable, Unknowable {
    case staff
    case pastInteractions = "past_interactions"
    case global
    case unknown

    public static var unknownCase: Self { .unknown }
  }

  public let source: Source
  public let account: Account
}
