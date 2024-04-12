// Copyright © 2024 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon
import Siren
import UIKit

extension AttributedString {
    /// Return a copy of this string, formatted with Siren for a given text style.
    func formatSiren(_ textStyle: UIFont.TextStyle) -> AttributedString {
        var formatted = self
        Siren.format(&formatted, textStyle: textStyle, baseIndent: .blockquoteIndent)

        // Hide parts of URLs marked as irrelevant.
        // Reverse order since we're going to be deleting things.
        // TODO: (Vyr) user preference for URL formatting
        for (linkClass, range) in formatted.runs[\.linkClass].reversed() {
            guard let linkClass = linkClass else { continue }

            switch linkClass {
            case .leadingInvisible:
                formatted.removeSubrange(range)
            case .trailingInvisible:
                formatted.characters.replaceSubrange(range, with: "…")
            default:
                break
            }
        }

        return formatted
    }

    /// Return a copy of this string, formatted with Siren for a given text style.
    func nsFormatSiren(_ textStyle: UIFont.TextStyle) -> NSAttributedString {
        return (try? NSAttributedString(formatSiren(textStyle), including: \.all)) ?? .init()
    }
}
