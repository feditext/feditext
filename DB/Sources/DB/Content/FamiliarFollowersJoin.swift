// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct FamiliarFollowersJoin: ContentDatabaseRecord {
  let followedAccountId: Account.Id
  let followingAccountId: Account.Id
}

extension FamiliarFollowersJoin {
  enum Columns {
    static let followedAccountId = Column(CodingKeys.followedAccountId)
    static let followingAccountId = Column(CodingKeys.followingAccountId)
  }

  static let followedAccount = belongsTo(AccountRecord.self, using: ForeignKey([Columns.followedAccountId]))
  static let followingAccount = belongsTo(AccountRecord.self, using: ForeignKey([Columns.followingAccountId]))
}
