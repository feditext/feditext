// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public struct EmojiViewModel {
  let identityContext: IdentityContext

  private let emoji: PickerEmoji

  public init(emoji: PickerEmoji, identityContext: IdentityContext) {
    self.emoji = emoji.applyingDefaultSkinTone(identityContext: identityContext)
    self.identityContext = identityContext
  }
}

extension EmojiViewModel {
  public var name: String { emoji.name }

  public var system: Bool { emoji.system }

  public var url: URL? {
    guard case .custom(let emoji, _) = emoji else { return nil }

    if identityContext.appPreferences.animateCustomEmojis {
      return emoji.url.url
    } else {
      return emoji.staticUrl.url
    }
  }
}
