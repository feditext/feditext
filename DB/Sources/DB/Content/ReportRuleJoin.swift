// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct ReportRuleJoin: ContentDatabaseRecord {
  let reportId: Report.Id
  let ruleId: Rule.Id
}

extension ReportRuleJoin {
  enum Columns {
    static let reportId = Column(CodingKeys.reportId)
    static let ruleId = Column(CodingKeys.ruleId)
  }

  static let rule = belongsTo(Rule.self, using: ForeignKey([Columns.ruleId]))
}
