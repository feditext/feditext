// Copyright © 2023 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct ReportRecord: ContentDatabaseRecord, Hashable {
    let id: Report.Id
    let actionTaken: Bool
}

extension ReportRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let actionTaken = Column(CodingKeys.actionTaken)
    }

    init(report: Report) {
        id = report.id
        actionTaken = report.actionTaken
    }
}
