// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct CardViewModel {
  private let card: Card

  init(card: Card) {
    self.card = card
  }
}

extension CardViewModel {
  public var url: URL? { card.url.url }

  public var displayHost: String? {
    if let host = url?.host, host.hasPrefix("www."),
      let withoutWww = host.components(separatedBy: "www.").last
    {
      return withoutWww
    } else {
      return url?.host
    }
  }

  public var title: String { card.title }

  public var description: String { card.description }

  public var imageURL: URL? { card.image?.url }
}

extension CardViewModel: Trendable {
  public var history: [History]? { card.history }
}
