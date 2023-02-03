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

public extension HTML {
    enum Key {
        /// Value expected to be a `LinkClass`.
        public static let linkClass: NSAttributedString.Key = .init("feditextLinkClass")
        /// Value expected to be an `Int` indicating how many levels of quote we're on.
        public static let quoteLevel: NSAttributedString.Key = .init("feditextQuoteLevel")
    }

    enum LinkClass: Int {
        case leadingInvisible = 1
        case ellipsis = 2
        case trailingInvisible = 3
        case mention = 4
        case hashtag = 5
    }
}

private extension HTML {
    static var attributedStringCache = NSCache<NSString, NSAttributedString>()

    /// This hack uses text background color to pass class information through the HTML parser,
    /// since there's no direct mechanism for attaching CSS classes to an attributed string.
    /// Currently `r` is for link class, `g` is for quote level, and `b` and `a` are unused.
    /// See https://docs.joinmastodon.org/spec/activitypub/#sanitization for what we expect from vanilla instances.
    static let style: String = """
        <style>
            a > span.invisible {
                background-color: rgb(1 0 0);
            }

            a > span.ellipsis {
                background-color: rgb(2 0 0);
            }

            a > span.ellipsis + span.invisible {
                background-color: rgb(3 0 0);
            }

            a.mention {
                background-color: rgb(4 0 0);
            }

            a.mention.hashtag {
                background-color: rgb(5 0 0);
            }

            blockquote {
                background-color: rgb(0 1 0);
            }

            blockquote blockquote {
                background-color: rgb(0 2 0);
            }

            blockquote blockquote blockquote {
                background-color: rgb(0 3 0);
            }

            blockquote blockquote blockquote blockquote {
                background-color: rgb(0 4 0);
            }

            blockquote blockquote blockquote blockquote blockquote {
                background-color: rgb(0 5 0);
            }

            blockquote blockquote blockquote blockquote blockquote blockquote {
                background-color: rgb(0 6 0);
            }

            blockquote blockquote blockquote blockquote blockquote blockquote blockquote {
                background-color: rgb(0 7 0);
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

            if let linkClass = Self.LinkClass(rawValue: Int((r * 255.0).rounded())) {
                attributed.addAttribute(Self.Key.linkClass, value: linkClass, range: range)
            }

            let quoteLevel = Int((g * 255.0).rounded())
            if quoteLevel > 0 {
                attributed.addAttribute(Self.Key.quoteLevel, value: quoteLevel, range: range)
            }
        }

        attributed.fixAttributes(in: entireString)
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
