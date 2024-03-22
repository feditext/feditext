// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

// swiftlint:disable nesting

/// Result of calling the Mastodon v1 instance API, a mix of instance metadata and client configuration.
/// See also: `DB.Identity.Instance` summary version in identity database.
public struct Instance: Codable {
    public struct URLs: Codable, Hashable {
        public let streamingApi: UnicodeURL?
    }

    public struct Stats: Codable, Hashable {
        public let userCount: Int
        public let statusCount: Int
        public let domainCount: Int
    }

    public struct Configuration: Codable, Hashable {
        public struct Statuses: Codable, Hashable {
            public let maxCharacters: Int?

            public init(maxCharacters: Int?) {
                self.maxCharacters = maxCharacters
            }
        }

        /// Present only in Glitch instances running PR #2221.
        public struct Reactions: Codable, Hashable {
            public let maxReactions: Int?

            public init(maxReactions: Int?) {
                self.maxReactions = maxReactions
            }
        }

        public let statuses: Statuses?
        public let reactions: Reactions?

        public init(statuses: Statuses?, reactions: Reactions?) {
            self.statuses = statuses
            self.reactions = reactions
        }
    }

    public let uri: String
    /// Mastodon servers use a bare domain in the `uri` field,
    /// but Akkoma and GotoSocial (at least) use an `https://` URL.
    public var domain: String {
        if let url = URL(string: uri), let host = url.host {
            return host
        } else {
            return uri
        }
    }
    public let title: String
    public let description: HTML
    public let shortDescription: String?
    public let email: String
    public let version: String
    @DecodableDefault.EmptyList public private(set) var languages: [String]
    @DecodableDefault.False public private(set) var registrations: Bool
    @DecodableDefault.False public private(set) var approvalRequired: Bool
    @DecodableDefault.False public private(set) var invitesEnabled: Bool
    public let urls: URLs
    public let stats: Stats
    public let thumbnail: UnicodeURL?
    public let contactAccount: Account?

    /// Present in everything except vanilla Mastodon and Firefish.
    public let maxTootChars: Int?
    /// Not present in Pleroma or Akkoma.
    public let configuration: Configuration?

    public var unifiedMaxTootChars: Int? {
        configuration?.statuses?.maxCharacters ?? maxTootChars
    }

    @DecodableDefault.EmptyList public private(set) var rules: [Rule]

    public init(
        uri: String,
        title: String,
        description: HTML,
        shortDescription: String?,
        email: String,
        version: String,
        urls: Instance.URLs,
        stats: Instance.Stats,
        thumbnail: UnicodeURL?,
        contactAccount: Account?,
        maxTootChars: Int?,
        configuration: Configuration?,
        rules: [Rule]
    ) {
        self.uri = uri
        self.title = title
        self.description = description
        self.shortDescription = shortDescription
        self.email = email
        self.version = version
        self.urls = urls
        self.stats = stats
        self.thumbnail = thumbnail
        self.contactAccount = contactAccount
        self.maxTootChars = maxTootChars
        self.configuration = configuration
        self.rules = rules
    }
}

extension Instance: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uri)
    }
}

// swiftlint:enable nesting
