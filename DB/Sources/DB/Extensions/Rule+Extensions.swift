// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Rule: ContentDatabaseRecord {}

extension Rule {
  enum Columns: String, ColumnExpression {
    case id
    case text
  }
}
