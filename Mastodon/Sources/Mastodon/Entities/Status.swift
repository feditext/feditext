// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public final class Status: Codable, Identifiable {
    public enum Visibility: String, Codable, Unknowable, Identifiable {
        case `public`
        case unlisted
        case `private`
        /// GotoSocial only, and only when authoring statuses:
        /// when fetching statuses, GtS coerces this to ``private``.
        case mutualsOnly = "mutuals_only"
        case direct
        case unknown

        public static var unknownCase: Self { .unknown }

        public var id: Self { self }
    }

    public let id: Status.Id
    public let uri: String
    public let createdAt: Date
    public let editedAt: Date?
    public let account: Account
    @DecodableDefault.EmptyHTML public private(set) var content: HTML
    public let visibility: Visibility
    public let sensitive: Bool
    public let spoilerText: String
    public let mediaAttachments: [Attachment]
    public let mentions: [Mention]
    public let tags: [Tag]
    public let emojis: [Emoji]
    public let reblogsCount: Int
    public let favouritesCount: Int
    @DecodableDefault.Zero public private(set) var repliesCount: Int
    public let application: Application?
    public let url: String?
    public let inReplyToId: Status.Id?
    public let inReplyToAccountId: Account.Id?
    /// Used by the Treehouse fork of Glitch, Fedibird, and Firefish.
    /// - See: https://gitea.treehouse.systems/treehouse/mastodon/src/branch/main/app/serializers/rest/status_serializer.rb
    /// - See: https://github.com/fedibird/mastodon/blob/main/app/serializers/rest/status_serializer.rb
    /// - See: https://git.joinfirefish.org/firefish/firefish/-/blob/develop/packages/backend/src/server/api/mastodon/converters.ts
    public let quote: Status?
    public let reblog: Status?
    public let poll: Poll?
    public let card: Card?
    /// ISO 639 country code from Mastodon, likely actually has script for Chinese,
    /// also likely to be full BCP 47 from other implementations such as GotoSocial.
    /// - See: https://docs.joinmastodon.org/entities/Status/#language
    public let language: String?
    public let text: String?
    @DecodableDefault.False public private(set) var favourited: Bool
    @DecodableDefault.False public private(set) var reblogged: Bool
    @DecodableDefault.False public private(set) var muted: Bool
    @DecodableDefault.False public private(set) var bookmarked: Bool
    public let pinned: Bool?

    /// Used by Glitch PR #2221 and future Firefish.
    @DecodableDefault.EmptyList public private(set) var reactions: [Reaction]
    /// Used by 2023-07-22 Firefish and 2023-07-28 Akkoma.
    @DecodableDefault.EmptyList public private(set) var emojiReactions: [Reaction]

    public var unifiedReactions: [Reaction] {
        if !reactions.isEmpty {
            return reactions
        }
        return emojiReactions
    }

    public init(
        id: Status.Id,
        uri: String,
        createdAt: Date,
        editedAt: Date?,
        account: Account,
        content: HTML,
        visibility: Status.Visibility,
        sensitive: Bool,
        spoilerText: String,
        mediaAttachments: [Attachment],
        mentions: [Mention],
        tags: [Tag],
        emojis: [Emoji],
        reblogsCount: Int,
        favouritesCount: Int,
        repliesCount: Int,
        application: Application?,
        url: String?,
        inReplyToId: Status.Id?,
        inReplyToAccountId: Account.Id?,
        quote: Status?,
        reblog: Status?,
        poll: Poll?,
        card: Card?,
        language: String?,
        text: String?,
        favourited: Bool,
        reblogged: Bool,
        muted: Bool,
        bookmarked: Bool,
        pinned: Bool?,
        reactions: [Reaction]
    ) {
        self.id = id
        self.uri = uri
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.account = account
        self.visibility = visibility
        self.sensitive = sensitive
        self.spoilerText = spoilerText
        self.mediaAttachments = mediaAttachments
        self.mentions = mentions
        self.tags = tags
        self.emojis = emojis
        self.reblogsCount = reblogsCount
        self.favouritesCount = favouritesCount
        self.application = application
        self.url = url
        self.inReplyToId = inReplyToId
        self.inReplyToAccountId = inReplyToAccountId
        self.quote = quote
        self.reblog = reblog
        self.poll = poll
        self.card = card
        self.language = language
        self.text = text
        self.pinned = pinned
        self.repliesCount = repliesCount
        self.content = content
        self.favourited = favourited
        self.reblogged = reblogged
        self.muted = muted
        self.bookmarked = bookmarked
        self.reactions = reactions
    }
}

public extension Status {
    typealias Id = String

    var displayStatus: Status {
        if quote == nil {
            // TODO: (Vyr) quote posts: do we need to resolve an entire reblog chain for a simple Firefish reblog?
            return reblog ?? self
        } else {
            return self
        }
    }

    var edited: Bool {
        editedAt != nil
    }

    var lastModified: Date {
        editedAt ?? createdAt
    }

    func with(source: StatusSource) -> Self {
        assert(
            self.id == source.id,
            "Trying to merge source for the wrong status!"
        )
        return .init(
            id: self.id,
            uri: self.uri,
            createdAt: self.createdAt,
            editedAt: self.editedAt,
            account: self.account,
            content: self.content,
            visibility: self.visibility,
            sensitive: self.sensitive,
            spoilerText: source.spoilerText,
            mediaAttachments: self.mediaAttachments,
            mentions: self.mentions,
            tags: self.tags,
            emojis: self.emojis,
            reblogsCount: self.reblogsCount,
            favouritesCount: self.favouritesCount,
            repliesCount: self.repliesCount,
            application: self.application,
            url: self.url,
            inReplyToId: self.inReplyToId,
            inReplyToAccountId: self.inReplyToAccountId,
            quote: self.quote,
            reblog: self.reblog,
            poll: self.poll,
            card: self.card,
            language: self.language,
            text: source.text,
            favourited: self.favourited,
            reblogged: self.reblogged,
            muted: self.muted,
            bookmarked: self.bookmarked,
            pinned: self.pinned,
            reactions: self.reactions
        )
    }
}

extension Status: Hashable {
    public static func == (lhs: Status, rhs: Status) -> Bool {
        lhs.id == rhs.id
            && lhs.uri == rhs.uri
            && lhs.createdAt == rhs.createdAt
            && lhs.editedAt == rhs.editedAt
            && lhs.account == rhs.account
            && lhs.content == rhs.content
            && lhs.visibility == rhs.visibility
            && lhs.sensitive == rhs.sensitive
            && lhs.spoilerText == rhs.spoilerText
            && lhs.mediaAttachments == rhs.mediaAttachments
            && lhs.mentions == rhs.mentions
            && lhs.tags == rhs.tags
            && lhs.emojis == rhs.emojis
            && lhs.reblogsCount == rhs.reblogsCount
            && lhs.favouritesCount == rhs.favouritesCount
            && lhs.repliesCount == rhs.repliesCount
            && lhs.application == rhs.application
            && lhs.url == rhs.url
            && lhs.inReplyToId == rhs.inReplyToId
            && lhs.inReplyToAccountId == rhs.inReplyToAccountId
            && lhs.quote == rhs.quote
            && lhs.reblog == rhs.reblog
            && lhs.poll == rhs.poll
            && lhs.card == rhs.card
            && lhs.language == rhs.language
            && lhs.text == rhs.text
            && lhs.favourited == rhs.favourited
            && lhs.reblogged == rhs.reblogged
            && lhs.muted == rhs.muted
            && lhs.bookmarked == rhs.bookmarked
            && lhs.pinned == rhs.pinned
            && lhs.reactions == rhs.reactions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
