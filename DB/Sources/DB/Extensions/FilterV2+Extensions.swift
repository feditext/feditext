// Copyright © 2026 Vyr Cossont. All rights reserved.

import Mastodon

// Create filters v2 API structs from persisted versions.

extension FilterV2 {
  init(_ info: FilterV2Info) {
    self.init(
      id: info.filter.id,
      title: info.filter.title,
      context: info.filter.context,
      expiresAt: info.filter.expiresAt,
      filterAction: info.filter.filterAction,
      keywords: info.keywords.map(FilterV2.Keyword.init),
      statuses: info.statuses.map(FilterV2.Status.init),
    )
  }
}

extension FilterV2.Keyword {
  init(_ record: FilterV2KeywordRecord) {
    self.init(id: record.id, keyword: record.keyword, wholeWord: record.wholeWord)
  }
}

extension FilterV2.Status {
  init(_ record: FilterV2StatusRecord) {
    self.init(id: record.id, statusId: record.statusId)
  }
}
