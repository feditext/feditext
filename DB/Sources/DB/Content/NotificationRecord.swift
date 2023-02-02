// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct NotificationRecord: ContentDatabaseRecord, Hashable {
    let id: String
    let type: MastodonNotification.NotificationType
    let accountId: Account.Id
    let createdAt: Date
    let statusId: Status.Id?
    let reportId: Report.Id?
}

extension NotificationRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let type = Column(CodingKeys.type)
        static let accountId = Column(CodingKeys.accountId)
        static let createdAt = Column(CodingKeys.createdAt)
        static let statusId = Column(CodingKeys.statusId)
        static let reportId = Column(CodingKeys.reportId)
    }

    static let account = belongsTo(AccountRecord.self)
    static let status = belongsTo(StatusRecord.self)
    static let report = belongsTo(ReportRecord.self)

    init(notification: MastodonNotification) {
        id = notification.id
        type = notification.type
        accountId = notification.account.id
        createdAt = notification.createdAt
        statusId = notification.status?.id
        reportId = notification.report?.id
    }
}
