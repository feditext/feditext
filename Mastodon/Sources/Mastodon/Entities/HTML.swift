// Copyright © 2020 Metabolist. All rights reserved.

import AppMetadata
import AppUrls
import Foundation
#if !os(macOS)
import UIKit
#else
import AppKit
#endif
import os
import Siren
import SwiftSoup
import SwiftUI

public struct HTML {
    public let raw: String
    public var attributed: NSAttributedString

    /// Temporary app-wide global for switching HTML parsers.
    /// Necessary because HTML parsing in Feditext is currently part of `Decodable` decoding,
    /// and has no other way to inject app state.
    public static var parser: Parser = .webkit {
        didSet {
            Self.attributedStringCache.removeAllObjects()
        }
    }
}

extension HTML: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(raw)
    }
}

extension HTML: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self.init(raw: raw)
    }

    public init(raw: String) {
        self.raw = raw
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
        /// Value expected to be a normalized `Tag.Name`.
        public static let hashtag: NSAttributedString.Key = .init("feditextHashtag")
    }

    /// Link classes that imply link semantics or have special formatting.
    enum LinkClass: Int, Codable {
        /// The scheme part of a shortened URL, normally hidden.
        case leadingInvisible = 1
        /// The host and partial path part of a shortened URL, always visible.
        /// So named because it has `…` as an `::after` decoration in Mastodon web client CSS.
        case ellipsis = 2
        /// The trailing part of a shortened URL, hidden in Mastodon web client CSS, normally replaced with an `…` by us.
        case trailingInvisible = 3
        /// Specifically a user mention.
        case mention = 4
        /// Specifically a hashtag.
        /// Many servers use both ``hashtag`` and ``mention`` for hashtag links in HTML, but we don't.
        case hashtag = 5
    }

    /// Choice of two HTML parsers so users can switch back and forth until we get Siren stable.
    enum Parser: String, Codable, CaseIterable, Identifiable {
        case webkit
        case siren

        public var id: Self { self }

        /// Signpost name for performance signposter.
        var signpostName: StaticString {
            switch self {
            case .webkit:
                "HTML.Parser.webkit"
            case .siren:
                "HTML.Parser.siren"
            }
        }
    }
}

public extension AttributeScopes {
    var feditext: FeditextAttributes.Type {
        FeditextAttributes.self
    }
    var all: AllAttributes.Type {
        AllAttributes.self
    }
}

public extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.FeditextAttributes, T>) -> T {
        return self[T.self]
    }
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.AllAttributes, T>) -> T {
        return self[T.self]
    }
}

public extension AttributeScopes {
    /// All of the string attributes that an iOS app might possibly care about.
    struct AllAttributes: AttributeScope {
        public let siren: AttributeScopes.SirenAttributes
        public let feditext: AttributeScopes.FeditextAttributes
        public let foundation: AttributeScopes.FoundationAttributes
        public let accessibility: AttributeScopes.AccessibilityAttributes
        public let swiftUI: AttributeScopes.SwiftUIAttributes
        #if !os(macOS)
        public let uiKit: AttributeScopes.UIKitAttributes
        #else
        public let appKit: AttributeScopes.AppKitAttributes
        #endif
    }
}

extension AttributeScopes {
    /// String attributes specific to Feditext (but not Siren).
    public struct FeditextAttributes: AttributeScope {
        let linkClass: FeditextLinkClassAttribute
        let quoteLevel: FeditextQuoteLevelAttribute
        let hashtag: FeditextHashtagAttribute
    }
}

public enum FeditextLinkClassAttribute: CodableAttributedStringKey {
    public static let name = HTML.Key.linkClass.rawValue
    public typealias Value = HTML.LinkClass
}

public enum FeditextQuoteLevelAttribute: CodableAttributedStringKey {
    public static let name = HTML.Key.quoteLevel.rawValue
    public typealias Value = Int
}

public enum FeditextHashtagAttribute: CodableAttributedStringKey {
    public static let name = HTML.Key.hashtag.rawValue
    public typealias Value = String
}

private extension HTML {
    /// Cache for parsed versions of HTML strings, keyed by the original HTML.
    static var attributedStringCache = NSCache<NSString, NSAttributedString>()

    #if DEBUG
    /// Performance signposter for HTML parsing.
    private static let signposter = OSSignposter(subsystem: AppMetadata.bundleIDBase, category: .pointsOfInterest)
    #else
    private static let signposter = OSSignposter.disabled
    #endif

    /// This hack uses text background color to pass class information through the WebKit HTML parser,
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

            a.mention.hashtag, a.hashtag {
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

    /// Parse HTML with SwiftSoup and then pass it to WebKit.
    static func parseWithWebkit(_ raw: String) -> NSMutableAttributedString {
        guard
            let sanitized: String = try? SwiftSoup.clean(
                raw,
                .basic()
                    .addTags("h1", "h2", "h3", "h4", "h5", "h6")
                    .addTags("kbd", "samp", "tt")
                    .addTags("s", "ins", "del")
                    .addAttributes("ol", "start", "reversed")
                    .addAttributes("li", "value")
                    .removeProtocols("a", "href", "ftp", "mailto")
                    .addProtocols(
                        "a",
                        "href",
                        "web+ap",
                        // From here on down: see https://docs.joinmastodon.org/spec/activitypub/#sanitization
                        "dat",
                        "dweb",
                        "ipfs",
                        "ipns",
                        "ssb",
                        "gopher",
                        "xmpp",
                        "magnet",
                        "gemini"
                    )
                    .addAttributes("a", "class", "rel", "type")
                    .removeEnforcedAttribute("a", "rel")
                    .addAttributes("span", "class")
            ),
            let attributed = NSMutableAttributedString(html: style.appending(sanitized))
        else {
            return NSMutableAttributedString()
        }

        let entireString = NSRange(location: 0, length: attributed.length)
        attributed.enumerateAttribute(.backgroundColor, in: entireString) { val, range, _ in
            #if !os(macOS)
            guard let color = val as? UIColor else {
                return
            }
            #else
            guard let color = val as? NSColor else {
                return
            }
            #endif

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

        return attributed
    }

    /// Parse the subset of HTML we support, including semantic classes where present
    /// (not all Fedi servers send them, and Mastodon does a terrible job of normalizing remote HTML).
    static func parse(_ raw: String) -> NSAttributedString {
        let signpostName = HTML.parser.signpostName
        let signpostInterval = Self.signposter.beginInterval(signpostName, id: Self.signposter.makeSignpostID())
        defer {
            Self.signposter.endInterval(signpostName, signpostInterval)
        }

        let attributed: NSMutableAttributedString
        switch HTML.parser {
        case .webkit:
            attributed = Self.parseWithWebkit(raw)
        case .siren:
            attributed = (try? NSMutableAttributedString(Self.parseWithSiren(raw), including: \.all))
            ?? NSMutableAttributedString()
        }

        // Trim trailing newline added by parser, probably for p tags.
        if let range = attributed.string.rangeOfCharacter(from: .newlines, options: .backwards),
              range.upperBound == attributed.string.endIndex {
            attributed.deleteCharacters(in: NSRange(range, in: attributed.string))
        }

        Self.rewriteLinks(attributed)

        let entireString = NSRange(location: 0, length: attributed.length)
        attributed.fixAttributes(in: entireString)

        #if DEBUG
        // TODO: (Vyr) debugging only. Remove this eventually.
        switch HTML.parser {
        case .webkit:
            #if !os(macOS)
            attributed.addAttribute(.backgroundColor, value: UIColor.systemGray, range: entireString)
            #else
            attributed.addAttribute(.backgroundColor, value: NSColor.systemGray, range: entireString)
            #endif
        case .siren:
            #if !os(macOS)
            attributed.addAttribute(.backgroundColor, value: UIColor.systemMint, range: entireString)
            #else
            attributed.addAttribute(.backgroundColor, value: NSColor.systemMint, range: entireString)
            #endif
        }
        #endif

        return attributed
    }

    /// Parse HTML with Siren.
    static func parseWithSiren(_ raw: String) -> AttributedString {
        guard let parsed = try? Siren.parse(raw) else { return .init() }

        // Format in a way compatible with the scaling in `adaptHtmlAttributes`.
        // TODO: (Vyr) we can move this there once Siren is the only parser
        #if !os(macOS)
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSize(12.0)
        #else
        let descriptor = NSFontDescriptor.preferredFontDescriptor(forTextStyle: .body).withSize(12.0)
        #endif
        var attributed = Siren.format(parsed, descriptor: descriptor)

        // Map Siren semantic classes to Feditext semantic classes.
        // (Siren doesn't keep track of previous elements.)
        var prevEllipsis = false
        for (sirenClasses, range) in attributed.runs[\.classes] {
            let sirenClasses = sirenClasses ?? []
            if sirenClasses.contains(.hashtag) {
                attributed[range].linkClass = .hashtag
                prevEllipsis = false
            } else if sirenClasses.contains(.mention) {
                attributed[range].linkClass = .mention
                prevEllipsis = false
            } else if sirenClasses.contains(.ellipsis) {
                attributed[range].linkClass = .ellipsis
                prevEllipsis = true
            } else if sirenClasses.contains(.invisible) {
                if prevEllipsis {
                    attributed[range].linkClass = .trailingInvisible
                } else {
                    attributed[range].linkClass = .leadingInvisible
                }
                prevEllipsis = false
            } else {
                prevEllipsis = false
            }
        }

        // Map Apple presentation intents to Feditext quote level.
        for (intent, range) in attributed.runs[\.presentationIntent] {
            let quoteLevel = intent?.components.filter { $0.kind == .blockQuote }.count ?? 0
            if quoteLevel > 0 {
                attributed[range].quoteLevel = quoteLevel
            }
        }

        return attributed
    }

    /// Apply heuristics to rewrite HTTPS links for mentions and hashtags into Feditext internal links.
    /// Assumes string has already been marked with Feditext attributes.
    static func rewriteLinks(_ attributed: NSMutableAttributedString) {
        let entireString = NSRange(location: 0, length: attributed.length)
        attributed.enumerateAttribute(.link, in: entireString) { val, nsRange, stop in
            guard let url = val as? URL else { return }

            guard let range = Range(nsRange, in: attributed.string) else {
                assertionFailure("Getting the substring range should always succeed")
                stop.pointee = true
                return
            }

            let substring = attributed.string[range]

            var linkClass = attributed.attribute(
                Self.Key.linkClass,
                at: nsRange.location,
                effectiveRange: nil
            ) as? Self.LinkClass

            if linkClass == nil {
                if substring.starts(with: "#") {
                    linkClass = .hashtag
                } else if substring.starts(with: "@") {
                    linkClass = .mention
                }
            }

            guard let linkClass = linkClass else {
                return
            }

            switch linkClass {
            case .hashtag:
                let trimmed: Substring
                if #available(iOS 16.0, macOS 13.0, *) {
                    trimmed = substring.trimmingPrefix("#")
                } else {
                    trimmed = substring.drop(while: { $0 == "#" })
                }
                let normalized = Tag.normalizeName(trimmed)
                attributed.addAttributes(
                    [
                        Self.Key.hashtag: normalized,
                        .link: AppUrl.tagTimeline(normalized).url
                    ],
                    range: nsRange
                )
            case .mention:
                attributed.addAttribute(
                    .link,
                    value: AppUrl.mention(url).url,
                    range: nsRange
                )
            default:
                break
            }
        }
    }
}

extension NSAttributedString {
    /// The built-in `init?(html:)` methods only exist on macOS,
    /// and `loadFromHTML` is async and invokes WebKit,
    /// so we roll our own convenience constructor from sanitized HTML.
    /// Which turns out to also invoke WebKit, and comes with some IPC overhead on iOS 17.
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
