// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Tag: Codable {
    public typealias Name = String

    public let name: Name
    public let url: UnicodeURL
    public let history: [History]?
    public let following: Bool?

    public init(name: Name, url: UnicodeURL, history: [History]?, following: Bool?) {
        self.name = name
        self.url = url
        self.history = history
        self.following = following
    }
}

public extension Tag {
    /// > Warning: Two tag names that are not equal may still represent the same tag.
    /// > Authoritative tag comparison should only be done server-side due to this… thing:
    /// > https://github.com/mastodon/mastodon/blob/main/app/lib/hashtag_normalizer.rb
    /// > https://github.com/mastodon/mastodon/blob/main/app/lib/ascii_folding.rb
    static func normalizeName(_ name: any StringProtocol) -> Tag.Name {
        // TODO: (Vyr) (i18n) implement the rest of that mess, assuming we're talking to a Mastodon server
        name.lowercased()
    }
}

extension Tag: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension Tag: Identifiable {
    public var id: Tag.Name { name }
}
