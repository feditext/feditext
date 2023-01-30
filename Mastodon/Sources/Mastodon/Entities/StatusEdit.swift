// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Represents a revision of a status that has been edited.
/// https://docs.joinmastodon.org/entities/StatusEdit/
public final class StatusEdit: Codable {
    public let createdAt: Date
    public let account: Account
    @DecodableDefault.EmptyHTML public private(set) var content: HTML
    public let sensitive: Bool
    public let spoilerText: String
    public let mediaAttachments: [Attachment]
    public let emojis: [Emoji]
    public let poll: Poll?

    public init(
        createdAt: Date,
        account: Account,
        content: HTML,
        sensitive: Bool,
        spoilerText: String,
        mediaAttachments: [Attachment],
        emojis: [Emoji],
        poll: Poll?
    ) {
        self.createdAt = createdAt
        self.account = account
        self.sensitive = sensitive
        self.spoilerText = spoilerText
        self.mediaAttachments = mediaAttachments
        self.emojis = emojis
        self.poll = poll
        self.content = content
    }
}

extension StatusEdit: Hashable {
    public static func == (lhs: StatusEdit, rhs: StatusEdit) -> Bool {
        lhs.createdAt == rhs.createdAt
            && lhs.account == rhs.account
            && lhs.content == rhs.content
            && lhs.sensitive == rhs.sensitive
            && lhs.spoilerText == rhs.spoilerText
            && lhs.mediaAttachments == rhs.mediaAttachments
            && lhs.emojis == rhs.emojis
            && lhs.poll == rhs.poll
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(account)
        hasher.combine(content)
        hasher.combine(sensitive)
        hasher.combine(spoilerText)
        hasher.combine(mediaAttachments)
        hasher.combine(emojis)
        hasher.combine(poll)
    }
}

extension StatusEdit: Identifiable {
    public var id: Date { createdAt }
}
