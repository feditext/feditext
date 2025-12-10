// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Suggestion {
  func save(_ db: Database) throws {
    try account.save(db)
    try SuggestionRecord(suggestion: self).save(db)
  }
}
