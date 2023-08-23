// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusInfo: Codable, Hashable, FetchableRecord {
    let record: StatusRecord
    let accountInfo: AccountInfo
    let relationship: Relationship?
    let quoteInfo: RelatedStatusInfo?
    let reblogInfo: RelatedStatusInfo?
    let showContentToggle: StatusShowContentToggle?
    let showAttachmentsToggle: StatusShowAttachmentsToggle?
}

extension StatusInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == StatusRecord {
        addingOptionalIncludes(
            request
                .including(required: AccountInfo.addingIncludes(StatusRecord.account).forKey(CodingKeys.accountInfo)))
    }

    // Hack, remove once GRDB supports chaining a required association behind an optional association
    static func addingIncludesForNotificationInfo<T: DerivableRequest>(
        _ request: T) -> T where T.RowDecoder == StatusRecord {
        addingOptionalIncludes(
            request
                .including(optional: AccountInfo.addingIncludes(StatusRecord.account).forKey(CodingKeys.accountInfo)))
    }

    static func request(_ request: QueryInterfaceRequest<StatusRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }

    // TODO: (Vyr) quote posts: should this include quotes?
    var filterableContent: String {
        (record.filterableContent + (reblogInfo?.record.filterableContent ?? [])).joined(separator: " ")
    }

    /// Does not include quoted post because its content visibility can be toggled separately.
    var showContentToggled: Bool {
        showContentToggle != nil || reblogInfo?.showContentToggle != nil
    }

    /// Does not include quoted post because its attachment visibility can be toggled separately.
    var showAttachmentsToggled: Bool {
        showAttachmentsToggle != nil || reblogInfo?.showAttachmentsToggle != nil
    }
}

private extension StatusInfo {
    static func addingOptionalIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == StatusRecord {
        request
            .including(optional: StatusRecord.relationship.forKey(CodingKeys.relationship))
            .including(optional: RelatedStatusInfo.addingIncludes(StatusRecord.quote).forKey(CodingKeys.quoteInfo))
            .including(optional: RelatedStatusInfo.addingIncludes(StatusRecord.reblog).forKey(CodingKeys.reblogInfo))
            .including(optional: StatusRecord.showContentToggle.forKey(CodingKeys.showContentToggle))
            .including(optional: StatusRecord.showAttachmentsToggle.forKey(CodingKeys.showAttachmentsToggle))
    }
}

/// Related status info for quote or reblog. Reduced from `StatusInfo`, doesn't need to be recursive.
struct RelatedStatusInfo: Codable, Hashable, FetchableRecord {
    let record: StatusRecord
    let accountInfo: AccountInfo
    let relationship: Relationship?
    let showContentToggle: StatusShowContentToggle?
    let showAttachmentsToggle: StatusShowAttachmentsToggle?
}

extension RelatedStatusInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == StatusRecord {
        request
            // Hack, change next line once GRDB supports chaining a required association behind an optional association
            .including(optional: AccountInfo.addingIncludes(StatusRecord.account).forKey(CodingKeys.accountInfo))
            .including(optional: StatusRecord.relationship.forKey(CodingKeys.relationship))
            .including(optional: StatusRecord.showContentToggle.forKey(CodingKeys.showContentToggle))
            .including(optional: StatusRecord.showAttachmentsToggle.forKey(CodingKeys.showAttachmentsToggle))
    }
}
