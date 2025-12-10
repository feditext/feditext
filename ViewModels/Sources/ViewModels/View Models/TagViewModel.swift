// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon

public struct TagViewModel {
  public let identityContext: IdentityContext

  private let tag: Tag

  init(tag: Tag, identityContext: IdentityContext) {
    self.tag = tag
    self.identityContext = identityContext
  }
}

extension TagViewModel: Identifiable {
  public var id: Tag.Name { Tag.normalizeName(tag.name) }
}

extension TagViewModel {
  public var name: String { "#".appending(tag.name) }
}

extension TagViewModel: Trendable {
  public var history: [History]? { tag.history }
}
