// Copyright © 2025 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension FilterV2: @retroactive PersistableRecord {}
extension FilterV2: @retroactive MutablePersistableRecord {}
extension FilterV2: @retroactive TableRecord {}
extension FilterV2: @retroactive EncodableRecord {}
extension FilterV2: @retroactive FetchableRecord {}
extension FilterV2: ContentDatabaseRecord {}

extension FilterV2 {
    enum Columns: String, ColumnExpression {
        case id
        case title
        case context
        case expiresAt
        case action
    }
    
    // TODO: (Vyr) persist filtered statuses too
}
