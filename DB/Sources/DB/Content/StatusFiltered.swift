// Copyright © 2024 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

/// Stores whether a given status should be filtered in a given context, and why.
/// Unique per combination of ID and context.
struct StatusFiltered: ContentDatabaseRecord, Hashable {
    let statusId: Status.Id
    let context: Filter.Context
    /// Will always contain at least one entry.
    /// Statuses with an empty `filtered` list are not filtered, and thus not stored.
    let filtered: [Status.FilterResult]

    enum Columns {
        static let statusId = Column(CodingKeys.statusId)
        static let context = Column(CodingKeys.context)
        static let filtered = Column(CodingKeys.filtered)
    }

    static func update(_ status: Status, _ filterContext: Filter.Context, _ db: Database) throws {
        if status.filtered.isEmpty {
            try StatusFiltered
                .filter(StatusFiltered.Columns.statusId == status.id)
                .filter(StatusFiltered.Columns.context == Filter.Context.notifications.rawValue)
                .deleteAll(db)
        } else {
            try StatusFiltered(
                statusId: status.id,
                context: filterContext,
                filtered: status.filtered
            )
            .save(db)
        }
    }
}
