// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct ReportRecord: ContentDatabaseRecord, Hashable {
    let id: Report.Id
    let actionTaken: Bool
    let actionTakenAt: Date?
    let category: Report.Category
    let comment: String
    let forwarded: Bool
    let createdAt: Date
    let statusIds: [Status.Id]
    let targetAccountId: Account.Id
}

extension ReportRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let actionTaken = Column(CodingKeys.actionTaken)
        static let actionTakenAt = Column(CodingKeys.actionTakenAt)
        static let category = Column(CodingKeys.category)
        static let comment = Column(CodingKeys.comment)
        static let forwarded = Column(CodingKeys.forwarded)
        static let createdAt = Column(CodingKeys.createdAt)
        static let statusIds = Column(CodingKeys.statusIds)
        static let targetAccountId = Column(CodingKeys.targetAccountId)
    }

    static let ruleJoins = hasMany(ReportRuleJoin.self)
    static let rules = hasMany(
        Rule.self,
        through: ruleJoins,
        using: ReportRuleJoin.rule
    )
    static let targetAccount = belongsTo(AccountRecord.self)

    init(report: Report) {
        id = report.id
        actionTaken = report.actionTaken
        actionTakenAt = report.actionTakenAt
        category = report.category
        comment = report.comment
        forwarded = report.forwarded
        createdAt = report.createdAt
        statusIds = report.statusIds ?? []
        targetAccountId = report.targetAccount.id
    }
}
