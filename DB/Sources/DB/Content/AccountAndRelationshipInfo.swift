// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountAndRelationshipInfo: Codable, Hashable, FetchableRecord {
  let accountInfo: AccountInfo
  let relationship: Relationship?
  let familiarFollowers: [AccountInfo]
  let suggestion: SuggestionRecord?
}

extension AccountAndRelationshipInfo {
  static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == AccountRecord {
    AccountInfo
      .addingIncludes(request)
      .including(optional: AccountRecord.relationship.forKey(CodingKeys.relationship))
      .including(optional: AccountRecord.suggestion.forKey(CodingKeys.suggestion))
      .including(all: AccountRecord.familiarFollowers.forKey(CodingKeys.familiarFollowers))
  }

  static func request(_ request: QueryInterfaceRequest<AccountRecord>) -> QueryInterfaceRequest<Self> {
    addingIncludes(request).asRequest(of: self)
  }
}
