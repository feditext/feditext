// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Report {
    func save(_ db: Database) throws {
        try ReportRecord(report: self).save(db)
    }

    init(record: ReportRecord) {
        self.init(
            id: record.id,
            actionTaken: record.actionTaken
        )
    }
}
