// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// A language tag and localized name.
/// When we drop support for iOS 15, maybe we can use `Locale.Language` instead.
/// These compare, hash, and identify based on their tag, but sort by name for display to the user.
/// Only the tag should ever be persisted.
public struct PrefsLanguage: Identifiable, Equatable, Comparable, Hashable {
    public typealias Tag = String

    public let tag: Tag
    public let localized: String

    public init(tag: PrefsLanguage.Tag) {
        self.tag = tag
        self.localized = Self.localizedStringExtended(forIdentifier: tag)
    }

    init(tag: PrefsLanguage.Tag, localized: String) {
        self.tag = tag
        self.localized = localized
    }

    init?(_ locale: Locale) {
        guard let tag = Self.reducedLanguageTag(locale) else {
            return nil
        }
        self.tag = tag
        self.localized = Self.localizedStringExtended(forIdentifier: tag)
    }

    public static func == (lhs: PrefsLanguage, rhs: PrefsLanguage) -> Bool {
        lhs.tag == rhs.tag
    }

    public static func < (lhs: PrefsLanguage, rhs: PrefsLanguage) -> Bool {
        return lhs.localized.localizedCaseInsensitiveCompare(rhs.localized) == .orderedAscending
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(tag)
    }

    public var id: PrefsLanguage.Tag { tag }
}

public extension PrefsLanguage {
    /// Combine OS and extended languages into a list of language tags and localized names.
    ///
    /// Note that Apple actually knows what they're doing, so the locale identifiers from the system are BCP 47
    /// language tags, not just ISO 639 language codes, and may contain language, script, region, and variant
    /// (for example, `zh-Hans`, `zh-Hant`, `zh-Hant-HK` vs. just `zh`).
    ///
    /// ActivityStreams explicitly supports these:
    /// https://www.w3.org/TR/activitystreams-core/#naturalLanguageValues
    /// But it's unclear what Mastodon language filtering does with them, given issues with `zh-Hans` vs. `zh-Hant`:
    /// https://github.com/mastodon/mastodon/issues/18538
    ///
    /// The user's language preference may be just a bare ISO 639 language code like `en` or `zh`,
    /// because that's all Mastodon supports, or it may be a BCP 47 tag if they set one locally in this app.
    /// Other Fedi instance servers may have full BCP 47 support.
    static func languageTagsAndNames(prefsLanguageTag: PrefsLanguage.Tag?) -> [PrefsLanguage] {
        var list: [PrefsLanguage] = []
        var tags: Set<PrefsLanguage.Tag> = Set()

        for prefsLanguage in Self.preferredLanguageTagsAndNames(prefsLanguageTag: prefsLanguageTag) {
            list.append(prefsLanguage)
            tags.insert(prefsLanguage.id)
        }

        // Languages from here down are combined and sorted.
        var tertiaryList: [PrefsLanguage] = []

        // List every language that the system has locale data for, but remove the region information
        // to keep the size of the list down. This is a compromise; some users have mentioned
        // wanting language filtering including region:
        // https://github.com/mastodon/mastodon/issues/18538#issuecomment-1149156394
        var systemIdentifiers = Set(Locale.availableIdentifiers)
        if #available(iOS 16, *) {
            systemIdentifiers.formUnion(Locale.LanguageCode.isoLanguageCodes.map { $0.identifier })
        } else {
            systemIdentifiers.formUnion(Locale.isoLanguageCodes)
        }
        for identifier in systemIdentifiers {
            guard let prefsLanguage = Self(Locale(identifier: identifier)),
                  !tags.contains(prefsLanguage.id) else {
                continue
            }
            tertiaryList.append(prefsLanguage)
            tags.insert(prefsLanguage.id)
        }

        // Add extended languages. They don't currently have regions or scripts.
        for (tag, localized) in extendedLanguageTagsAndLocalizedStrings {
            guard !tags.contains(tag) else {
                continue
            }
            tertiaryList.append(PrefsLanguage(tag: tag, localized: localized))
        }

        // Add tertiary to the list after default and secondary languages, in sorted order.
        tertiaryList.sort()
        list.append(contentsOf: tertiaryList)

        return list
    }

    /// Language tags and names for just the languages that the user prefers,
    /// based on Mastodon prefs, current locale, and system preferred languages.
    static func preferredLanguageTagsAndNames(prefsLanguageTag: PrefsLanguage.Tag?) -> [PrefsLanguage] {
        var list: [PrefsLanguage] = []
        var tags: Set<PrefsLanguage.Tag> = Set()

        // User's preferences default language first.
        if let tag = prefsLanguageTag {
            let prefsLanguage = PrefsLanguage(tag: tag)
            list.append(prefsLanguage)
            tags.insert(prefsLanguage.tag)
        }

        // User's locale language.
        if let prefsLanguage = PrefsLanguage(Locale.current),
           !tags.contains(prefsLanguage.tag) {
            list.append(prefsLanguage)
            tags.insert(prefsLanguage.tag)
        }

        // User's preferred secondary languages, in their specified order.
        // This is actually a list of locale identifiers:
        // https://developer.apple.com/documentation/foundation/nslocale/1415614-preferredlanguages
        for identifier in Locale.preferredLanguages {
            guard let prefsLanguage = PrefsLanguage(Locale(identifier: identifier)),
                  !tags.contains(prefsLanguage.tag) else {
                continue
            }
            list.append(prefsLanguage)
            tags.insert(prefsLanguage.tag)
        }

        return list
    }
}

private extension PrefsLanguage {
    /// Return the BCP 47 tag for a locale's language, without the region, and usually without the script.
    /// Chinese and Cantonese are special cases and we always retain a script (if present) for them.
    static func reducedLanguageTag(_ locale: Locale) -> PrefsLanguage.Tag? {
        if #available(iOS 16, *) {
            let regionless = Locale(
                languageCode: locale.language.languageCode,
                script: locale.language.languageCode == .chinese || locale.language.languageCode == .cantonese
                ? locale.language.script
                    : nil,
                languageRegion: nil
            )
            let identifier = regionless.identifier(.bcp47)
            return identifier
        } else {
            guard let languageCode = locale.languageCode else {
                return nil
            }
            if let scriptCode = locale.scriptCode,
               languageCode == "zh" || languageCode == "yue" {
                return "\(languageCode)-\(scriptCode)"
            }
            return languageCode
        }
    }

    /// Look up the localized name for a language in the OS's list first, then ours, then use a fallback.
    /// Covers languages the OS doesn't know about and never fails.
    static func localizedStringExtended(forIdentifier identifier: String) -> String {
        if let localized = Locale.current.localizedString(forIdentifier: identifier) {
            return localized
        }
        if let localized = Self.extendedLanguageTagsAndLocalizedStrings[identifier] {
            return localized
        }
        return String.localizedStringWithFormat(
            NSLocalizedString("language.bcp-47-tag-%@", comment: ""),
            identifier
        )
    }

    /// BCP 47 tags and names for languages supported by Mastodon 4.1.0rc3 but not in iOS 16's language list.
    static var extendedLanguageTagsAndLocalizedStrings: [String: String] {
        [
            "bh": NSLocalizedString("language.extended.name.bh", comment: ""),
            "cnr": NSLocalizedString("language.extended.name.cnr", comment: ""),
            "kmr": NSLocalizedString("language.extended.name.kmr", comment: ""),
            "ldn": NSLocalizedString("language.extended.name.ldn", comment: ""),
            // This one is in the list as `.uncoded` but doesn't have a name.
            "mis": NSLocalizedString("language.extended.name.mis", comment: ""),
            "tl": NSLocalizedString("language.extended.name.tl", comment: ""),
            "tok": NSLocalizedString("language.extended.name.tok", comment: ""),
            "zba": NSLocalizedString("language.extended.name.zba", comment: "")
        ]
    }
}
