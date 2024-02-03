// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon
import UIKit
import ViewModels

/// Display familiar followers for an account.
/// This label may combine emoji from multiple different servers,
/// so we can't use `NSMutableAttributedString.insert(emojis:, view:, identityContext:)` directly.
class FamiliarFollowersLabel: AnimatedAttachmentLabel {
    /// Must be set so we know whether to animate emoji.
    var identityContext: IdentityContext? {
        didSet {
            showDisplayNames()
        }
    }

    var accounts: [Account] = [] {
        didSet {
            showDisplayNames()
        }
    }

    private func showDisplayNames() {
        guard let identityContext = identityContext else {
            return
        }

        let head = accounts.prefix(maxAccounts)
        let tailCount = accounts.count - maxAccounts
        let hasTail = tailCount > 0

        let formatString: String
        switch accounts.count {
        case 0:
            text = ""
            return
        case 1:
            formatString = NSLocalizedString("account.familiar-followers.1-%@", comment: "")
        case 2:
            formatString = NSLocalizedString("account.familiar-followers.2-%@-%@", comment: "")
        case 3:
            formatString = NSLocalizedString("account.familiar-followers.3-%@-%@-%@", comment: "")
        default:
            formatString = NSLocalizedString("account.familiar-followers.more-%@-%@-%@-%ld", comment: "")
        }

        let attributedDisplayNames = head.map { account in
            let attributedDisplayName = NSMutableAttributedString(string: account.displayName)
            attributedDisplayName.insert(emojis: account.emojis, view: self, identityContext: identityContext)
            return attributedDisplayName
        }

        var args: [Any] = []
        args.append(contentsOf: attributedDisplayNames)
        if hasTail {
            args.append(tailCount)
        }

        let attributedText = formatAttributed(formatString, args)
        attributedText.resizeAttachments(toLineHeight: font.lineHeight)
        self.attributedText = attributedText
    }
}

/// Show up to this many accounts.
private let maxAccounts = 3

/// `NSString`-style formatting, but with an attributed result, and `%@` will interpolate other attributed strings.
private func formatAttributed(_ formatString: String, _ args: [Any]) -> NSMutableAttributedString {
    let attributed = NSMutableAttributedString(string: formatString)
    let positions = formatSpecPositions(formatString)
    assert(positions.count == args.count)
    // In reverse order so we don't invalidate the positions.
    for ((formatSpec, range), arg) in zip(positions, args).reversed() {
        if formatSpec == "%@", let arg = arg as? NSAttributedString {
            attributed.replaceCharacters(in: range, with: arg)
        } else if let arg = arg as? CVarArg {
            attributed.replaceCharacters(in: range, with: String(format: String(formatSpec), arg))
        } else {
            assertionFailure("Unexpected format argument type")
            attributed.replaceCharacters(in: range, with: "")
        }
    }
    return attributed
}

private let formatPattern = #"%(?:@|ld\b)"#

/// Find a tiny subset of `NSString` format specifiers.
/// Return them and their positions using `NSString`-style ranges.
private func formatSpecPositions(_ formatString: String) -> [(Substring, NSRange)] {
    if #available(iOS 16, *) {
        let regex: Regex<Substring>
        do {
            regex = try Regex(formatPattern, as: Substring.self)
        } catch {
            assertionFailure("Regex should always compile")
            return []
        }
        return formatString.matches(of: regex).map { match in
            (match.output, NSRange(match.range, in: formatString))
        }
    } else {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: formatPattern)
        } catch {
            assertionFailure("Regex should always compile")
            return []
        }
        let entireString = NSRange(formatString.startIndex..<formatString.endIndex, in: formatString)
        return regex.matches(in: formatString, range: entireString).compactMap { match in
            guard let substringRange = Range(match.range, in: formatString) else {
                assertionFailure("Range should always be valid")
                return nil
            }
            return (formatString[substringRange], match.range)
        }
    }
}
