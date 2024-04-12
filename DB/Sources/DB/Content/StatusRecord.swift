// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusRecord: ContentDatabaseRecord, Hashable {
    let id: Status.Id
    let uri: String
    let createdAt: Date
    let editedAt: Date?
    let accountId: Account.Id
    let content: HTML
    let visibility: Status.Visibility
    let sensitive: Bool
    let spoilerText: String
    let mediaAttachments: [Attachment]
    let mentions: [Mention]
    let tags: [Tag]
    let emojis: [Emoji]
    let reblogsCount: Int
    let favouritesCount: Int
    let repliesCount: Int
    let application: Application?
    let url: String?
    let inReplyToId: Status.Id?
    let inReplyToAccountId: Account.Id?
    let quoteId: Status.Id?
    let reblogId: Status.Id?
    let poll: Poll?
    let card: Card?
    let language: String?
    let text: String?
    let favourited: Bool
    let reblogged: Bool
    let muted: Bool
    let bookmarked: Bool
    let pinned: Bool?
    let reactions: [Reaction]?
}

extension StatusRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let uri = Column(CodingKeys.uri)
        static let createdAt = Column(CodingKeys.createdAt)
        static let editedAt = Column(CodingKeys.editedAt)
        static let accountId = Column(CodingKeys.accountId)
        static let content = Column(CodingKeys.content)
        static let visibility = Column(CodingKeys.visibility)
        static let sensitive = Column(CodingKeys.sensitive)
        static let spoilerText = Column(CodingKeys.spoilerText)
        static let mediaAttachments = Column(CodingKeys.mediaAttachments)
        static let mentions = Column(CodingKeys.mentions)
        static let tags = Column(CodingKeys.tags)
        static let emojis = Column(CodingKeys.emojis)
        static let reblogsCount = Column(CodingKeys.reblogsCount)
        static let favouritesCount = Column(CodingKeys.favouritesCount)
        static let repliesCount = Column(CodingKeys.repliesCount)
        static let application = Column(CodingKeys.application)
        static let url = Column(CodingKeys.url)
        static let inReplyToId = Column(CodingKeys.inReplyToId)
        static let inReplyToAccountId = Column(CodingKeys.inReplyToAccountId)
        static let quoteId = Column(CodingKeys.quoteId)
        static let reblogId = Column(CodingKeys.reblogId)
        static let poll = Column(CodingKeys.poll)
        static let card = Column(CodingKeys.card)
        static let language = Column(CodingKeys.language)
        static let text = Column(CodingKeys.text)
        static let favourited = Column(CodingKeys.favourited)
        static let reblogged = Column(CodingKeys.reblogged)
        static let muted = Column(CodingKeys.muted)
        static let bookmarked = Column(CodingKeys.bookmarked)
        static let pinned = Column(CodingKeys.pinned)
        static let reactions = Column(CodingKeys.reactions)
    }
}

extension StatusRecord {
    static let account = belongsTo(AccountRecord.self)
    static let relationship = hasOne(
        Relationship.self,
        through: Self.account,
        using: AccountRecord.relationship
    )
    static let accountMoved = hasOne(
        AccountRecord.self,
        through: Self.account,
        using: AccountRecord.moved
    )

    static let quote = belongsTo(
        StatusRecord.self,
        using: ForeignKey([Columns.quoteId])
    )

    static let reblog = belongsTo(
        StatusRecord.self,
        using: ForeignKey([Columns.reblogId])
    )

    static let showContentToggle = hasOne(StatusShowContentToggle.self)

    static let showAttachmentsToggle = hasOne(StatusShowAttachmentsToggle.self)

    static let ancestorJoins = hasMany(
        StatusAncestorJoin.self,
        using: ForeignKey([StatusAncestorJoin.Columns.parentId])
    ).order(StatusAncestorJoin.Columns.order)
    static let descendantJoins = hasMany(
        StatusDescendantJoin.self,
        using: ForeignKey([StatusDescendantJoin.Columns.parentId])
    ).order(StatusDescendantJoin.Columns.order)
    static let ancestors = hasMany(
        StatusRecord.self,
        through: ancestorJoins,
        using: StatusAncestorJoin.status
    )
    static let descendants = hasMany(
        StatusRecord.self,
        through: descendantJoins,
        using: StatusDescendantJoin.status
    )

    var ancestors: QueryInterfaceRequest<StatusInfo> {
        StatusInfo.request(request(for: Self.ancestors))
    }

    var descendants: QueryInterfaceRequest<StatusInfo> {
        StatusInfo.request(request(for: Self.descendants))
    }

    // TODO: (Vyr) filters: should this include attachment alt text?
    var filterableContent: [String] {
        [String(content.attrStr.characters), spoilerText] + (poll?.options.map(\.title) ?? [])
    }

    init(status: Status) {
        id = status.id
        uri = status.uri
        createdAt = status.createdAt
        editedAt = status.editedAt
        accountId = status.account.id
        content = status.content
        visibility = status.visibility
        sensitive = status.sensitive
        spoilerText = status.spoilerText
        mediaAttachments = status.mediaAttachments
        mentions = status.mentions
        tags = status.tags
        emojis = status.emojis
        reblogsCount = status.reblogsCount
        favouritesCount = status.favouritesCount
        repliesCount = status.repliesCount
        application = status.application
        url = status.url
        inReplyToId = status.inReplyToId
        inReplyToAccountId = status.inReplyToAccountId
        quoteId = status.quote?.id
        reblogId = status.reblog?.id
        poll = status.poll
        card = status.card
        language = status.language
        text = status.text
        favourited = status.favourited
        reblogged = status.reblogged
        muted = status.muted
        bookmarked = status.bookmarked
        pinned = status.pinned
        reactions = status.unifiedReactions
    }
}
