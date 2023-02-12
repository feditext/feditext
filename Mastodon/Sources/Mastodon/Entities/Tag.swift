// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Tag: Codable {
    /// > Warning: Two tag names that are not equal may still represent the same tag.
    /// > Authoritative tag comparison should only be done server-side due to this… thing:
    /// > https://github.com/mastodon/mastodon/blob/main/app/lib/hashtag_normalizer.rb
    /// > https://github.com/mastodon/mastodon/blob/main/app/lib/ascii_folding.rb
    public typealias Name = String

    public let name: Name
    public let url: UnicodeURL
    public let history: [History]?
    public let following: Bool?
}

public extension Tag {
    struct History: Codable, Hashable {
        public let day: String
        public let uses: String
        public let accounts: String
    }
}

extension Tag: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
