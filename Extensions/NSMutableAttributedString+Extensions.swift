// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SDWebImage
import UIKit
import ViewModels

extension NSMutableAttributedString {
    func insert(emojis: [Emoji], identityContext: IdentityContext, onLoad: (() -> Void)? = nil) {
        for emoji in emojis {
            let token = ":\(emoji.shortcode):"

            while let tokenRange = string.range(of: token) {
                let attachment = AnimatedTextAttachment()
                let imageURL: URL

                if identityContext.appPreferences.animateCustomEmojis {
                    imageURL = emoji.url.url
                } else {
                    imageURL = emoji.staticUrl.url
                }

                attachment.imageView.sd_setImage(with: imageURL) { image, _, _, _ in
                    attachment.image = image

                    onLoad?()
                }

                attachment.accessibilityLabel = emoji.shortcode
                replaceCharacters(in: NSRange(tokenRange, in: string), with: NSAttributedString(attachment: attachment))
            }
        }
    }

    func insert(emojis: [Emoji], view: UIView & EmojiInsertable, identityContext: IdentityContext) {
        insert(emojis: emojis, identityContext: identityContext) {
            DispatchQueue.main.async {
                view.setNeedsDisplay()
            }
        }
    }

    func resizeAttachments(toLineHeight lineHeight: CGFloat) {
        enumerateAttribute(.attachment, in: NSRange(location: 0, length: length), options: []) { attribute, _, _ in
            guard let attachment = attribute as? NSTextAttachment else { return }

            attachment.bounds = CGRect(x: 0, y: lineHeight * -0.25, width: lineHeight, height: lineHeight)
        }
    }

    func appendWithSeparator(_ string: NSAttributedString) {
        append(.init(string: .separator))
        append(string)
    }

    func appendWithSeparator(_ string: String) {
        appendWithSeparator(.init(string: string))
    }

    /// Get size of body text produced by `NSAttributedString`'s HTML parser.
    /// Default is observed height on macOS 13.
    private static let htmlBodyTextHeight: CGFloat = (NSAttributedString(html: "x")?
        .attribute(.font, at: 0, effectiveRange: nil) as? UIFont)?
        .pointSize
    ?? 12.0

    /// Replace HTML parser fonts with equivalent system fonts, appropriately scaled.
    func adaptHtmlFonts(style: UIFont.TextStyle) {
        let systemFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let entireString = NSRange(location: 0, length: length)
        enumerateAttribute(.font, in: entireString) { val, range, _ in
            guard let font = val as? UIFont else {
                return
            }
            let descriptor = font.fontDescriptor
            let size = descriptor.pointSize / Self.htmlBodyTextHeight * systemFontDescriptor.pointSize
            var traits = descriptor.symbolicTraits
            traits.remove(.classMask)
            guard let newDescriptor = systemFontDescriptor.withSize(size).withSymbolicTraits(traits) else {
                return
            }
            let newFont = UIFont(descriptor: newDescriptor, size: 0.0)
            addAttribute(.font, value: newFont, range: range)
        }
        fixAttributes(in: entireString)
    }
}
