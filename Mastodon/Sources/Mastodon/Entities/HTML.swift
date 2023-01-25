// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
#if !os(macOS)
import UIKit
#else
import AppKit
#endif
import SwiftSoup

public struct HTML: Hashable {
    public let raw: String
    public let attributed: NSAttributedString
}

extension HTML: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        raw = try container.decode(String.self)

        if let cachedAttributedString = Self.attributedStringCache.object(forKey: raw as NSString) {
            attributed = cachedAttributedString
        } else {
            attributed = Self.parse(raw)
            Self.attributedStringCache.setObject(attributed, forKey: raw as NSString)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(raw)
    }
}

private extension HTML {
    static var attributedStringCache = NSCache<NSString, NSAttributedString>()

    // https://docs.joinmastodon.org/spec/activitypub/#sanitization

    // Mark the invisible span after an ellipsis span for replacement with "…".
    // ::after pseudo-elements don't work in this context.
    static let style: String = """
        <style>
            a > span.invisible {
                display: none;
            }

            a > span.ellipsis + span.invisible {
                display: inherit;
                background-color: rgb(255 0 0);
            }
        </style>
    """

    static func parse(_ raw: String) -> NSAttributedString {
        guard
            let sanitized: String = try? SwiftSoup.clean(
                raw,
                .basic()
                    .addTags("h1", "h2", "h3", "h4", "h5", "h6")
                    .addTags("kbd", "samp", "tt")
                    .addTags("s", "ins", "del")
                    .removeProtocols("a", "href", "ftp", "mailto")
                    .addAttributes("span", "class")
            ),
            let attributed = NSMutableAttributedString(html: style.appending(sanitized))
        else {
            return NSAttributedString()
        }

        // Trim trailing newline added by parser, probably for p tags.
        if let range = attributed.string.rangeOfCharacter(from: .newlines, options: .backwards),
              range.upperBound == attributed.string.endIndex {
            attributed.deleteCharacters(in: NSRange(range, in: attributed.string))
        }

        // This hack uses text background color to pass class information through the HTML parser,
        // since there's no direct mechanism for attaching CSS classes to an attributed string.
        let entireString = NSRange(location: 0, length: attributed.length)
        attributed.enumerateAttribute(.backgroundColor, in: entireString) { val, range, _ in
            guard let color = val as? UIColor else {
                return
            }
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: nil)
            attributed.removeAttribute(.backgroundColor, range: range)
            if r == 1.0 && g == 0.0 && b == 0.0 {
                attributed.replaceCharacters(in: range, with: "…")
            }
        }

        attributed.fixAttributes(in: NSRange(location: 0, length: attributed.length))
        return attributed
    }
}

extension NSAttributedString {
    /// The built-in `init?(html:)` methods only exist on macOS,
    /// and `loadFromHTML` is async and invokes WebKit,
    /// so we roll our own convenience constructor from sanitized HTML.
    ///
    /// Note that this constructor should not be used for general-purpose HTML:
    /// https://developer.apple.com/documentation/foundation/nsattributedstring/1524613-init#discussion
    public convenience init?(html: String) {
        guard let data = html.data(using: .utf8) else {
            return nil
        }
        try? self.init(
            data: data,
            options: [
                .characterEncoding: NSUTF8StringEncoding,
                .documentType: NSAttributedString.DocumentType.html
            ],
            documentAttributes: nil
        )
    }
}
