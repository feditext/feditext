// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

/// Used with the v1 filter API and applied client-side.
public struct Filter: Codable, Identifiable {
    public enum Context: String, Codable, Unknowable {
        case home
        case notifications
        case `public`
        case thread
        case account
        case unknown

        public static var unknownCase: Self { .unknown }
    }

    public let id: Id
    public var phrase: String
    public var context: [Context]
    public var expiresAt: Date?
    public var irreversible: Bool
    public var wholeWord: Bool
}

public extension Filter {
    typealias Id = String

    static let newFilterId: Id = "com.metabolist.metatext.new-filter-id"
    static let new = Self(id: newFilterId,
                          phrase: "",
                          context: [],
                          expiresAt: nil,
                          irreversible: false,
                          wholeWord: true)
}

extension Filter: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Filter {
    // swiftlint:disable line_length
    // Adapted from https://github.com/tootsuite/mastodon/blob/bf477cee9f31036ebf3d164ddec1cebef5375513/app/javascript/mastodon/selectors/index.js#L43
    // swiftlint:enable line_length
    public var regularExpression: String {
        var expression = NSRegularExpression.escapedPattern(for: phrase)

        if wholeWord {
            if expression.range(of: #"^[\w]"#, options: .regularExpression) != nil {
                expression = #"\b"#.appending(expression)
            }

            if expression.range(of: #"[\w]$"#, options: .regularExpression) != nil {
                expression.append(#"\b"#)
            }
        }

        return expression
    }
}

extension Filter.Context: Identifiable {
    public var id: Self { self }
}

/// Used with the v2 filter API and applied server-side.
public struct FilterV2: Codable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let context: [Filter.Context]
    public let expiresAt: Date?
    public let filterAction: Action
    public let keywords: [Keyword]
    public let statuses: [Status]

    public init(
        id: String,
        title: String,
        context: [Filter.Context],
        expiresAt: Date?,
        filterAction: Action,
        keywords: [Keyword],
        statuses: [Status]
    ) {
        self.id = id
        self.title = title
        self.context = context
        self.expiresAt = expiresAt
        self.filterAction = filterAction
        self.keywords = keywords
        self.statuses = statuses
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public enum Action: String, Codable, Unknowable {
        case warn
        case hide
        case unknown

        public static var unknownCase: Self { .unknown }
    }

    public struct Keyword: Codable, Identifiable, Hashable {
        public let id: String
        public let keyword: String
        public let wholeWord: Bool

        public init(id: String, keyword: String, wholeWord: Bool) {
            self.id = id
            self.keyword = keyword
            self.wholeWord = wholeWord
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    public struct Status: Codable, Identifiable, Hashable {
        public let id: String
        public let statusId: Mastodon.Status.Id

        public init(id: String, statusId: Mastodon.Status.Id) {
            self.id = id
            self.statusId = statusId
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
