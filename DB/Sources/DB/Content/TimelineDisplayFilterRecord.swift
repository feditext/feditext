// Copyright © 2025 Vyr Cossont. All rights reserved.

import Foundation
import GRDB

/// Persistence struct for ``DisplayFilter`` attached to a given ``Timeline``.
struct TimelineDisplayFilterRecord: ContentDatabaseRecord, Hashable {
  let timelineID: Timeline.Id
  let displayFilter: DisplayFilter

  init(_ timeline: Timeline, _ displayFilter: DisplayFilter) {
    self.timelineID = timeline.id
    self.displayFilter = displayFilter
  }

  enum Columns {
    static let timelineID = Column(CodingKeys.timelineID)
    static let displayFilter = Column(CodingKeys.displayFilter)
  }
}
