// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Report {
  func save(_ db: Database) throws {
    try targetAccount.save(db)
    try ReportRecord(report: self).save(db)
    for ruleId in ruleIds ?? [] {
      try ReportRuleJoin(reportId: id, ruleId: ruleId).save(db)
    }
  }

  init(info: ReportInfo) {
    let record = info.record
    self.init(
      id: record.id,
      actionTaken: record.actionTaken,
      actionTakenAt: record.actionTakenAt,
      category: record.category,
      comment: record.comment,
      forwarded: record.forwarded,
      createdAt: record.createdAt,
      statusIds: record.statusIds,
      ruleIds: info.rules.map { $0.id },
      targetAccount: Account(info: info.targetAccountInfo)
    )
  }
}
