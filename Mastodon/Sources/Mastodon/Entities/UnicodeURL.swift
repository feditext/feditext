// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public struct UnicodeURL {
  public let raw: String
  public let url: URL?

  public init(raw: String) {
    self.raw = raw
    self.url = URL(unicodeString: raw)
  }

  public init(url: URL) {
    self.raw = url.absoluteString
    self.url = url
  }
}

extension UnicodeURL: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(raw)
  }
}

extension UnicodeURL: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(raw: try container.decode(String.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    try container.encode(raw)
  }
}
