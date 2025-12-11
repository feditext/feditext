// Copyright © 2022 Metabolist. All rights reserved.

import UIKit

extension UIFont {
  func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
    let descriptor = fontDescriptor.withSymbolicTraits(traits)
    return UIFont(descriptor: descriptor!, size: 0)
  }

  func bold() -> UIFont {
    withTraits(traits: .traitBold)
  }

  func italic() -> UIFont {
    withTraits(traits: .traitItalic)
  }
}
