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
    /// HTML source. Not sanitized.
    public let raw: String
    /// Parsed and annotated with Feditext attributes, but without fonts or paragraph styles.
    public let attrStr: AttributedString
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
        public let linkClass: FeditextLinkClassAttribute
        public let quoteLevel: FeditextQuoteLevelAttribute
        public let hashtag: FeditextHashtagAttribute
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
    public typealias Value = Tag.ID
}

private final class AttributedStringCacheValue {
    let attrStr: AttributedString

    init(attrStr: AttributedString) {
        self.attrStr = attrStr
    }
}

private extension HTML {
    /// Cache for parsed versions of HTML strings, keyed by the original HTML.
    static let attributedStringCache = NSCache<NSString, AttributedStringCacheValue>()

    /// Parse the subset of HTML we support, including semantic classes where present
    /// (not all Fedi servers send them, and Mastodon does a terrible job of normalizing remote HTML).
    static func parse(_ raw: String) -> AttributedString {
        #if DEBUG
        let signposter = OSSignposter(subsystem: AppMetadata.bundleIDBase, category: .pointsOfInterest)
        let signpostName: StaticString = "HTML.parser.siren"
        let signpostInterval = signposter.beginInterval(signpostName, id: signposter.makeSignpostID())
        defer {
            signposter.endInterval(signpostName, signpostInterval)
        }
        #endif

        var attrStr: AttributedString
        do {
            attrStr = try Siren.parse(raw)
        } catch {
            #if DEBUG
            fatalError("Siren.parse failed: \(error)")
            #else
            return .init()
            #endif
        }

        Self.mapSirenAttrsToFeditextAttrs(&attrStr)
        Self.rewriteLinks(&attrStr)

        return attrStr
    }

    /// Map some Siren attributes to their Feditext equivalents.
    static func mapSirenAttrsToFeditextAttrs(_ attrStr: inout AttributedString) {
        // Map Siren semantic link classes to Feditext semantic link classes.
        // (Siren doesn't keep track of previous elements, and its ranges may have leading and trailing whitespace.)
        var prevEllipsis = false
        // Handle one link run at a time so as to avoid concatenating the classes for two adjacent links into one run.
        for (_, linkRange) in attrStr.runs[\.link] {
            for (sirenClasses, sirenRange) in attrStr[linkRange].runs[\.classes] {
                // Exclude leading and trailing whitespace from range with Feditext attribute.
                if sirenRange.isEmpty { continue }
                var lower = sirenRange.lowerBound
                var upperInclusive = attrStr.index(beforeCharacter: sirenRange.upperBound)
                while lower <= upperInclusive && attrStr.characters[lower].isWhitespace {
                    lower = attrStr.index(afterCharacter: lower)
                }
                while lower <= upperInclusive && attrStr.characters[upperInclusive].isWhitespace {
                    upperInclusive = attrStr.index(beforeCharacter: upperInclusive)
                }
                if !(lower <= upperInclusive) {
                    prevEllipsis = false
                    continue
                }
                let range = lower...upperInclusive

                let sirenClasses = sirenClasses ?? []
                if sirenClasses.contains(.hashtag) {
                    attrStr[range].linkClass = .hashtag
                    prevEllipsis = false
                } else if sirenClasses.contains(.mention) {
                    attrStr[range].linkClass = .mention
                    prevEllipsis = false
                } else if sirenClasses.contains(.ellipsis) {
                    attrStr[range].linkClass = .ellipsis
                    prevEllipsis = true
                } else if sirenClasses.contains(.invisible) {
                    if prevEllipsis {
                        attrStr[range].linkClass = .trailingInvisible
                    } else {
                        attrStr[range].linkClass = .leadingInvisible
                    }
                    prevEllipsis = false
                } else {
                    prevEllipsis = false
                }
            }
        }

        // Map Apple presentation intents to Feditext quote level.
        for (intent, range) in attrStr.runs[\.presentationIntent] {
            let quoteLevel = intent?.components.filter { $0.kind == .blockQuote }.count ?? 0
            if quoteLevel > 0 {
                attrStr[range].quoteLevel = quoteLevel
            }
        }
    }

    /// Apply heuristics to rewrite HTTPS links for mentions and hashtags into Feditext internal links.
    /// Assumes string has already been marked with Feditext attributes.
    static func rewriteLinks(_ attrStr: inout AttributedString) {
        for (url, linkRange) in attrStr.runs[\.link] {
            guard let url = url else { continue }

            // Exclude leading and trailing whitespace from range with link attribute.
            if linkRange.isEmpty { continue }
            var lower = linkRange.lowerBound
            var upperInclusive = attrStr.index(beforeCharacter: linkRange.upperBound)
            while lower <= upperInclusive && attrStr.characters[lower].isWhitespace {
                lower = attrStr.index(afterCharacter: lower)
            }
            while lower <= upperInclusive && attrStr.characters[upperInclusive].isWhitespace {
                upperInclusive = attrStr.index(beforeCharacter: upperInclusive)
            }
            if !(lower <= upperInclusive) { continue }
            let range = lower...upperInclusive

            let substring = attrStr[range]

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
                attrStr[range].hashtag = normalized
                attrStr[linkRange].link = nil
                attrStr[range].link = AppUrl.tagTimeline(normalized).url

            case .mention:
                attrStr[linkRange].link = nil
                attrStr[range].link = AppUrl.mention(url).url

            case .ellipsis, .leadingInvisible, .trailingInvisible:
                break
            }
        }
    }
}
