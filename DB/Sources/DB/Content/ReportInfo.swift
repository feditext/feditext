// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct ReportInfo: Codable, Hashable, FetchableRecord {
  let record: ReportRecord
  let rules: [Rule]
  let targetAccountInfo: AccountInfo
}

extension ReportInfo {
  static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == ReportRecord {
    addingOptionalIncludes(
      request
        .including(
          required: AccountInfo.addingIncludes(ReportRecord.targetAccount)
            .forKey(CodingKeys.targetAccountInfo)
        )
    )
  }

  // Hack, remove once GRDB supports chaining a required association behind an optional association
  static func addingIncludesForNotificationInfo<T: DerivableRequest>(
    _ request: T
  ) -> T where T.RowDecoder == ReportRecord {
    addingOptionalIncludes(
      request
        .including(
          optional: AccountInfo.addingIncludes(ReportRecord.targetAccount)
            .forKey(CodingKeys.targetAccountInfo)
        )
    )
  }

  private static func addingOptionalIncludes<T: DerivableRequest>(
    _ request: T
  ) -> T where T.RowDecoder == ReportRecord {
    request
      .including(all: ReportRecord.rules.forKey(CodingKeys.rules))
  }

  static func request(_ request: QueryInterfaceRequest<ReportRecord>) -> QueryInterfaceRequest<Self> {
    addingIncludes(request).asRequest(of: self)
  }
}
