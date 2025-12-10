// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Card: Codable, Equatable {
  public enum CardType: String, Codable, Hashable, Unknowable {
    case link, photo, video, rich, unknown

    public static var unknownCase: Self { .unknown }
  }

  public let url: UnicodeURL
  public let title: String
  public let description: String
  public let type: CardType
  public let authorName: String?
  public let authorUrl: String?
  public let providerName: String?
  public let providerUrl: String?
  public let html: String?
  public let width: Int?
  public let height: Int?
  public let image: UnicodeURL?
  public let embedUrl: String?
  /// Only present when returned from trends API:
  /// https://docs.joinmastodon.org/entities/PreviewCard/#history
  public let history: [History]?
}

extension Card: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(url)
  }
}
