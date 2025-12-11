// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct NotificationInfo: Codable, Hashable, FetchableRecord {
  let record: NotificationRecord
  let accountInfo: AccountInfo
  let statusInfo: StatusInfo?
  let reportInfo: ReportInfo?
}

extension NotificationInfo {
  static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == NotificationRecord {
    request.including(
      required: AccountInfo.addingIncludes(NotificationRecord.account)
        .forKey(CodingKeys.accountInfo)
    )
    .including(
      optional: StatusInfo.addingIncludesForNotificationInfo(NotificationRecord.status)
        .forKey(CodingKeys.statusInfo)
    )
    .including(
      optional: ReportInfo.addingIncludesForNotificationInfo(NotificationRecord.report)
        .forKey(CodingKeys.reportInfo)
    )
  }

  static func request(_ request: QueryInterfaceRequest<NotificationRecord>) -> QueryInterfaceRequest<Self> {
    addingIncludes(request).asRequest(of: self)
  }
}
