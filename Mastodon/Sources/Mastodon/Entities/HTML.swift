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
    public let attrStr: AttributedString

    public var attributed: NSAttributedString {
        (try? NSAttributedString(attrStr, including: \.all)) ?? NSAttributedString()
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
        if let cacheValue = Self.attributedStringCache.object(forKey: raw as NSString) {
            attrStr = cacheValue.attrStr
        } else {
            attrStr = Self.parse(raw)
            Self.attributedStringCache.setObject(.init(attrStr: attrStr), forKey: raw as NSString)
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
        /// The trailing part of a shortened URL, hidden in Mastodon web client CSS, normally replaced with `…` by us.
        case trailingInvisible = 3
        /// Specifically a user mention.
        case mention = 4
        /// Specifically a hashtag.
        /// Many servers use both ``hashtag`` and ``mention`` for hashtag links in HTML, but we don't.
        case hashtag = 5
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

private final class AttributedStringCacheValue {
    let attrStr: AttributedString

    init(attrStr: AttributedString) {
        self.attrStr = attrStr
    }
}

private extension HTML {
    /// Cache for parsed versions of HTML strings, keyed by the original HTML.
    static var attributedStringCache = NSCache<NSString, AttributedStringCacheValue>()

    #if DEBUG
    /// Performance signposter for HTML parsing.
    private static let signposter = OSSignposter(subsystem: AppMetadata.bundleIDBase, category: .pointsOfInterest)
    #else
    private static let signposter = OSSignposter.disabled
    #endif

    /// Parse the subset of HTML we support, including semantic classes where present
    /// (not all Fedi servers send them, and Mastodon does a terrible job of normalizing remote HTML).
    static func parse(_ raw: String) -> AttributedString {
        let signpostName: StaticString = "HTML.parser.siren"
        let signpostInterval = Self.signposter.beginInterval(signpostName, id: Self.signposter.makeSignpostID())
        defer {
            Self.signposter.endInterval(signpostName, signpostInterval)
        }

        var attrStr = Self.parseWithSiren(raw)

        Self.trimTrailingWhitespace(&attrStr)
        Self.rewriteLinks(&attrStr)

        return attrStr
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
        var attributed = Siren.format(parsed, descriptor: descriptor, baseIndent: 12.0)

        // Map Siren semantic classes to Feditext semantic classes.
        // (Siren doesn't keep track of previous elements, and its ranges may have leading and trailing whitespace.)
        var prevEllipsis = false
        for (sirenClasses, sirenRange) in attributed.runs[\.classes] {
            // Exclude leading and trailing whitespace from range with Feditext attribute.
            if sirenRange.isEmpty { continue }
            var lower = sirenRange.lowerBound
            var upperInclusive = attributed.index(beforeCharacter: sirenRange.upperBound)
            while lower <= upperInclusive && attributed.characters[lower].isWhitespace {
                lower = attributed.index(afterCharacter: lower)
            }
            while lower <= upperInclusive && attributed.characters[upperInclusive].isWhitespace {
                upperInclusive = attributed.index(beforeCharacter: upperInclusive)
            }
            if !(lower <= upperInclusive) { continue }
            let range = lower...upperInclusive

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

    static func trimTrailingWhitespace(_ attrStr: inout AttributedString) {
        if !attrStr.characters.isEmpty {
            var startOfTrailingWhitespace = attrStr.endIndex
            while startOfTrailingWhitespace > attrStr.startIndex {
                let prev = attrStr.index(beforeCharacter: startOfTrailingWhitespace)
                if !attrStr.characters[prev].isWhitespace {
                    break
                }
                startOfTrailingWhitespace = prev
            }
            attrStr.removeSubrange(startOfTrailingWhitespace..<attrStr.endIndex)
        }
    }

    /// Apply heuristics to rewrite HTTPS links for mentions and hashtags into Feditext internal links.
    /// Assumes string has already been marked with Feditext attributes.
    static func rewriteLinks(_ attributed: inout AttributedString) {
        for (url, linkRange) in attributed.runs[\.link] {
            guard let url = url else { continue }

            // Exclude leading and trailing whitespace from range with link attribute.
            if linkRange.isEmpty { continue }
            var lower = linkRange.lowerBound
            var upperInclusive = attributed.index(beforeCharacter: linkRange.upperBound)
            while lower <= upperInclusive && attributed.characters[lower].isWhitespace {
                lower = attributed.index(afterCharacter: lower)
            }
            while lower <= upperInclusive && attributed.characters[upperInclusive].isWhitespace {
                upperInclusive = attributed.index(beforeCharacter: upperInclusive)
            }
            if !(lower <= upperInclusive) { continue }
            let range = lower...upperInclusive

            let substring = attributed[range]

            var linkClass = substring.linkClass

            if linkClass == nil {
                if substring.characters.starts(with: "#") {
                    linkClass = .hashtag
                } else if substring.characters.starts(with: "@") {
                    linkClass = .mention
                }
            }

            guard let linkClass = linkClass else {
                continue
            }

            switch linkClass {
            case .hashtag:
                let trimmed: AttributedString.CharacterView.SubSequence
                if #available(iOS 16.0, macOS 13.0, *) {
                    trimmed = substring.characters.trimmingPrefix("#")
                } else {
                    trimmed = substring.characters.drop(while: { $0 == "#" })
                }
                let normalized = Tag.normalizeName(String(trimmed))
                attributed[range].hashtag = normalized
                attributed[linkRange].link = nil
                attributed[range].link = AppUrl.tagTimeline(normalized).url

            case .mention:
                attributed[linkRange].link = nil
                attributed[range].link = AppUrl.mention(url).url

            case .ellipsis, .leadingInvisible, .trailingInvisible:
                break
            }
        }
    }
}
