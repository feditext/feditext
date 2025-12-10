// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

extension PickerEmoji {
  public func applyingDefaultSkinTone(identityContext: IdentityContext) -> PickerEmoji {
    if case .system(let systemEmoji, let infrequentlyUsed) = self,
      let defaultEmojiSkinTone = identityContext.appPreferences.defaultEmojiSkinTone
    {
      return .system(systemEmoji.applying(skinTone: defaultEmojiSkinTone), infrequentlyUsed: infrequentlyUsed)
    } else {
      return self
    }
  }
}
