// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

/// Used for Mastodon announcements and Glitch/Firefish status emoji reactions.
/// - See: https://docs.joinmastodon.org/entities/Reaction/
/// - See: https://codeberg.org/firefish/firefish/src/branch/develop/packages/megalodon/src/entities/reaction.ts
public struct Reaction: Codable, Hashable {
  public let name: String
  public let count: Int
  public let me: Bool
  public let url: UnicodeURL?
  public let staticUrl: UnicodeURL?

  public init(
    name: String,
    count: Int,
    me: Bool,
    url: UnicodeURL?,
    staticUrl: UnicodeURL?
  ) {
    self.name = name
    self.count = count
    self.me = me
    self.url = url
    self.staticUrl = staticUrl
  }
}
