// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Marker: Codable, Hashable {
  public let lastReadId: String
  public let updatedAt: Date
  public let version: Int
}

extension Marker {
  public enum Timeline: String, Codable {
    case home
    case notifications
  }
}
