// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// The useful cross-version subset of the somewhat overengineered NodeInfo standard for Fediverse instance metadata.
///
/// - See: https://github.com/jhass/nodeinfo
public struct NodeInfo: Codable, Hashable {
  /// Whether this server allows open self-registration.
  public let openRegistrations: Bool
  /// Metadata about server software in use.
  public let software: Software
  /// Usage statistics for this server.
  public let usage: Usage

  public init(
    openRegistrations: Bool,
    software: Software,
    usage: Usage? = nil
  ) {
    self.openRegistrations = openRegistrations
    self.software = software
    self.usage = usage ?? .init()
  }

  public struct Software: Codable, Hashable {
    /// The canonical name of this server software.
    public let name: String
    /// The version of this server software.
    public let version: String
    /// The url of the homepage of this server software.
    public let homepage: String?
    /// The url of the source code repository of this server software.
    public let repository: String?

    public init(
      name: String,
      version: String,
      homepage: String? = nil,
      repository: String? = nil
    ) {
      self.name = name
      self.version = version
      self.homepage = homepage
      self.repository = repository
    }
  }

  public struct Usage: Codable, Hashable {
    /// The amount of comments that were made by users that are registered on this server.
    public let localComments: Int?
    /// The amount of posts that were made by users that are registered on this server.
    public let localPosts: Int?
    /// Statistics about the users of this server.
    public let users: Users

    public init(
      localComments: Int? = nil,
      localPosts: Int? = nil,
      users: Users? = nil
    ) {
      self.localComments = localComments
      self.localPosts = localPosts
      self.users = users ?? .init()
    }
  }

  public struct Users: Codable, Hashable {
    /// The amount of users that signed in at least once in the last 180 days.
    public let activeHalfyear: Int?
    /// The amount of users that signed in at least once in the last 30 days.
    public let activeMonth: Int?
    /// The total amount of on this server registered users.
    public let total: Int?

    public init(
      activeHalfyear: Int? = nil,
      activeMonth: Int? = nil,
      total: Int? = nil
    ) {
      self.activeHalfyear = activeHalfyear
      self.activeMonth = activeMonth
      self.total = total
    }
  }
}
