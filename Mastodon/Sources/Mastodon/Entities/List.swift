// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

/// https://docs.joinmastodon.org/entities/List/
public struct List: Codable, Identifiable {
  public let id: Id
  public let title: String
  /// Which replies should be shown in the list.
  public let repliesPolicy: RepliesPolicy?
  /// If true, do not show posts from users on this list in the home timeline.
  /// - See: https://github.com/mastodon/mastodon/pull/22048
  public let exclusive: Bool?

  public init(
    id: Id,
    title: String,
    repliesPolicy: RepliesPolicy? = nil,
    exclusive: Bool? = nil
  ) {
    self.id = id
    self.title = title
    self.repliesPolicy = repliesPolicy
    self.exclusive = exclusive
  }

  /// https://docs.joinmastodon.org/entities/List/#replies_policy
  public enum RepliesPolicy: String, Codable, Identifiable, Unknowable {
    /// Show replies to any followed user.
    case followed
    /// Show replies to members of the list.
    case list
    /// Show replies to no one.
    case none

    case unknown

    public var id: Self { self }

    public static var unknownCase: Self { .unknown }
  }
}

extension List {
  public typealias Id = String
}

extension List: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
