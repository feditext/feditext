// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public final class Status: Codable, Identifiable {
    public enum Visibility: String, Codable, Unknowable {
        case `public`
        case unlisted
        case `private`
        case direct
        case unknown

        public static var unknownCase: Self { .unknown }
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
    public let reblog: Status?
    public let poll: Poll?
    public let card: Card?
    public let language: String?
    public let text: String?
    @DecodableDefault.False public private(set) var favourited: Bool
    @DecodableDefault.False public private(set) var reblogged: Bool
    @DecodableDefault.False public private(set) var muted: Bool
    @DecodableDefault.False public private(set) var bookmarked: Bool
    public let pinned: Bool?

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
        reblog: Status?,
        poll: Poll?,
        card: Card?,
        language: String?,
        text: String?,
        favourited: Bool,
        reblogged: Bool,
        muted: Bool,
        bookmarked: Bool,
        pinned: Bool?
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
    }
}

public extension Status {
    typealias Id = String

    var displayStatus: Status {
        reblog ?? self
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
            reblog: self.reblog,
            poll: self.poll,
            card: self.card,
            language: self.language,
            text: source.text,
            favourited: self.favourited,
            reblogged: self.reblogged,
            muted: self.muted,
            bookmarked: self.bookmarked,
            pinned: self.pinned
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
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
