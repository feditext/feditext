// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Poll: Codable {
  public struct Option: Codable, Hashable {
    public var title: String
    public var votesCount: Int
  }

  public let id: Id
  public let expiresAt: Date?
  public let expired: Bool
  public let multiple: Bool
  public let votesCount: Int
  public let votersCount: Int?
  @DecodableDefault.False public private(set) var voted: Bool
  @DecodableDefault.EmptyList public private(set) var ownVotes: [Int]
  public let options: [Option]
  @DecodableDefault.EmptyList public private(set) var emojis: [Emoji]
}

extension Poll: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension Poll {
  public typealias Id = String
}
