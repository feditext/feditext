// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

extension Locale {
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
    static func languageTagsAndNames(prefsLanguageTag prefsTag: String?) -> [PrefsLanguage] {
        var list: [PrefsLanguage] = []
        var tags: Set<String> = Set()

        // User's preferences default language first.
        if let prefsTag = prefsTag,
           let tag = Locale(identifier: prefsTag).reducedLanguageTag {
            list.append(PrefsLanguage(
                id: tag,
                localized: Self.localizedStringExtended(forIdentifier: tag)
            ))
            tags.insert(tag)
        }

        // User's locale language.
        if let tag = Locale.current.reducedLanguageTag,
           !tags.contains(tag) {
            list.append(PrefsLanguage(
                id: tag,
                localized: Self.localizedStringExtended(forIdentifier: tag)
            ))
            tags.insert(tag)
        }

        // User's preferred secondary languages, in their specified order.
        // This is actually a list of locale identifiers:
        // https://developer.apple.com/documentation/foundation/nslocale/1415614-preferredlanguages
        for identifier in Locale.preferredLanguages {
            guard let tag = Locale(identifier: identifier).reducedLanguageTag,
                  !tags.contains(tag) else {
                continue
            }
            list.append(PrefsLanguage(
                id: tag,
                localized: Self.localizedStringExtended(forIdentifier: tag)
            ))
            tags.insert(tag)
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
            guard let tag = Locale(identifier: identifier).reducedLanguageTag,
                  !tags.contains(tag) else {
                continue
            }
            tertiaryList.append(PrefsLanguage(
                id: tag,
                localized: Self.localizedStringExtended(forIdentifier: tag)
            ))
            tags.insert(tag)
        }

        // Add extended languages. They don't currently have regions or scripts.
        for tag in extendedLanguageTagsAndLocalizedStrings.keys {
            guard !tags.contains(tag) else {
                continue
            }
            tertiaryList.append(PrefsLanguage(
                id: tag,
                localized: Self.localizedStringExtended(forIdentifier: tag)
            ))
        }

        // Add tertiary to the list after default and secondary languages, in sorted order.
        tertiaryList.sort(using: PrefsLanguageComparator())
        list.append(contentsOf: tertiaryList)

        return list
    }
}

private extension Locale {
    /// BCP 47 tags and names for languages supported by Mastodon 4.1.0rc3 but not in iOS 16's language list.
    static let extendedLanguageTagsAndLocalizedStrings: [String: String] = [
        "bh": NSLocalizedString("language.extended.name.bh", comment: ""),
        "cnr": NSLocalizedString("language.extended.name.cnr", comment: ""),
        "kmr": NSLocalizedString("language.extended.name.kmr", comment: ""),
        "ldn": NSLocalizedString("language.extended.name.ldn", comment: ""),
        "tl": NSLocalizedString("language.extended.name.tl", comment: ""),
        "tok": NSLocalizedString("language.extended.name.tok", comment: ""),
        "zba": NSLocalizedString("language.extended.name.zba", comment: "")
    ]

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

    /// Return the BCP 47 tag for a locale's language, without the region, and usually without the script.
    /// Chinese and Cantonese are special cases and we always retain a script (if present) for them.
    var reducedLanguageTag: String? {
        if #available(iOS 16, *) {
            let regionless = Locale(
                languageCode: language.languageCode,
                script: language.languageCode == .chinese || language.languageCode == .cantonese
                    ? language.script
                    : nil,
                languageRegion: nil
            )
            let identifier = regionless.identifier(.bcp47)
            return identifier
        } else {
            guard let languageCode = languageCode else {
                return nil
            }
            if let scriptCode = scriptCode,
               languageCode == "zh" || languageCode == "yue" {
                return "\(languageCode)-\(scriptCode)"
            }
            return languageCode
        }
    }
}

/// Sort a language list by the localized name.
private struct PrefsLanguageComparator: SortComparator {
    private var localizedComparator = String.Comparator(options: [.caseInsensitive, .widthInsensitive])

    func compare(_ lhs: PrefsLanguage, _ rhs: PrefsLanguage) -> ComparisonResult {
        return localizedComparator.compare(lhs.localized, rhs.localized)
    }

    typealias Compared = PrefsLanguage

    var order: SortOrder {
        get {
            localizedComparator.order
        }
        set {
            localizedComparator.order = newValue
        }
    }
}

/// A language tag and localized name.
/// When we drop support for iOS 15, maybe we can use `Locale.Language` instead.
struct PrefsLanguage: Identifiable {
    public let id: String
    public let localized: String
}
