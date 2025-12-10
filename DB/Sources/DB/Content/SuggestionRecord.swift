// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct SuggestionRecord: ContentDatabaseRecord, Hashable {
  let id: Account.Id
  let source: Suggestion.Source

  enum Columns {
    static let id = Column(CodingKeys.id)
    static let source = Column(CodingKeys.source)
  }

  static let account = belongsTo(AccountRecord.self)

  init(suggestion: Suggestion) {
    id = suggestion.account.id
    source = suggestion.source
  }
}
