// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Status {
    func save(_ db: Database) throws {
        try account.save(db)

        // Save quotes and reblogs recursively:
        // - Firefish may serve us an entire quote or reblog chain at once.
        // - Mastodon and Akkoma definitely do *not* do this.
        if let quote = quote {
            try quote.save(db)
        }
        if let reblog = reblog {
            try reblog.save(db)
        }

        try StatusRecord(status: self).save(db)
    }

    convenience init(info: StatusInfo) {
        // Note that we currently do not retrieve quotes or reblogs recursively.
        // In the case of quotes, one level should always be enough.

        var quote: Status?
        if let quoteInfo = info.quoteInfo {
            quote = Status(
                record: quoteInfo.record,
                account: Account(info: quoteInfo.accountInfo),
                quote: nil,
                reblog: nil
            )
        }

        var reblog: Status?
        if let reblogInfo = info.reblogInfo {
            reblog = Status(
                record: reblogInfo.record,
                account: Account(info: reblogInfo.accountInfo),
                quote: nil,
                reblog: nil
            )
        }

        self.init(
            record: info.record,
            account: Account(info: info.accountInfo),
            quote: quote,
            reblog: reblog
        )
    }
}

private extension Status {
    convenience init(record: StatusRecord, account: Account, quote: Status?, reblog: Status?) {
        self.init(
            id: record.id,
            uri: record.uri,
            createdAt: record.createdAt,
            editedAt: record.editedAt,
            account: account,
            content: record.content,
            visibility: record.visibility,
            sensitive: record.sensitive,
            spoilerText: record.spoilerText,
            mediaAttachments: record.mediaAttachments,
            mentions: record.mentions,
            tags: record.tags,
            emojis: record.emojis,
            reblogsCount: record.reblogsCount,
            favouritesCount: record.favouritesCount,
            repliesCount: record.repliesCount,
            application: record.application,
            url: record.url,
            inReplyToId: record.inReplyToId,
            inReplyToAccountId: record.inReplyToAccountId,
            quote: quote,
            reblog: reblog,
            poll: record.poll,
            card: record.card,
            language: record.language,
            text: record.text,
            favourited: record.favourited,
            reblogged: record.reblogged,
            muted: record.muted,
            bookmarked: record.bookmarked,
            pinned: record.pinned,
            // Workaround for a problem with Sharkey, which sends both `Status.reactions`
            // and `Status.emojiReactions` with identical data, causing `record.reactions`
            // to contain duplicate entries, which results in a duplicated item crash:
            // https://github.com/feditext/feditext/issues/323#issuecomment-1925916923
            // This de-dupes reaction data containing existing duplicate reactions,
            // and can be removed once Sharkey users have upgraded.
            reactions: Array(Set(record.reactions ?? []))
        )
    }
}
