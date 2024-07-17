// Copyright © 2024 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

/// A status with one of these attached should be shown even if it would normally be hidden by a filter.
struct StatusShowFilteredToggle: ContentDatabaseRecord, Hashable {
    let statusId: Status.Id
}

extension StatusShowFilteredToggle {
    enum Columns {
        static let statusId = Column(CodingKeys.statusId)
    }
}
