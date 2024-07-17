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
    let showFilteredToggle: StatusShowFilteredToggle?
    let filtered: StatusFiltered?
}

extension StatusInfo {
    static func addingIncludes<T: DerivableRequest>(
        _ request: T,
        _ filterContext: Filter.Context?
    ) -> T where T.RowDecoder == StatusRecord {
        addingOptionalIncludes(
            request
                .including(required: AccountInfo.addingIncludes(StatusRecord.account).forKey(CodingKeys.accountInfo)),
            filterContext
        )
    }

    // Hack, remove once GRDB supports chaining a required association behind an optional association
    static func addingIncludesForNotificationInfo<T: DerivableRequest>(
        _ request: T
    ) -> T where T.RowDecoder == StatusRecord {
        addingOptionalIncludes(
            request
                .including(optional: AccountInfo.addingIncludes(StatusRecord.account).forKey(CodingKeys.accountInfo)),
            .notifications
        )
    }

    static func request(
        _ request: QueryInterfaceRequest<StatusRecord>,
        _ filterContext: Filter.Context?
    ) -> QueryInterfaceRequest<Self> {
        addingIncludes(request, filterContext).asRequest(of: self)
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

    /// Does not include quoted post because its filter override can be toggled separately.
    var showFilteredToggled: Bool {
        showFilteredToggle != nil || reblogInfo?.showFilteredToggle != nil
    }

    /// Set a different set of filter results.
    /// Used when applying v1 filters client-side.
    func with(filtered: StatusFiltered) -> Self {
        .init(
            record: self.record,
            accountInfo: self.accountInfo,
            relationship: self.relationship,
            quoteInfo: self.quoteInfo,
            reblogInfo: self.reblogInfo,
            showContentToggle: self.showContentToggle,
            showAttachmentsToggle: self.showAttachmentsToggle,
            showFilteredToggle: self.showFilteredToggle,
            filtered: filtered
        )
    }
}

private extension StatusInfo {
    static func addingOptionalIncludes<T: DerivableRequest>(
        _ request: T,
        _ filterContext: Filter.Context?
    ) -> T where T.RowDecoder == StatusRecord {
        var request = request
            .including(optional: StatusRecord.relationship.forKey(CodingKeys.relationship))
            .including(optional: RelatedStatusInfo.addingIncludes(StatusRecord.quote, filterContext).forKey(CodingKeys.quoteInfo))
            .including(optional: RelatedStatusInfo.addingIncludes(StatusRecord.reblog, filterContext).forKey(CodingKeys.reblogInfo))
            .including(optional: StatusRecord.showContentToggle.forKey(CodingKeys.showContentToggle))
            .including(optional: StatusRecord.showAttachmentsToggle.forKey(CodingKeys.showAttachmentsToggle))
            .including(optional: StatusRecord.showFilteredToggle.forKey(CodingKeys.showFilteredToggle))
        if let filterContext = filterContext {
            request = request.including(optional: StatusRecord.filtered(filterContext).forKey(CodingKeys.filtered))
        }
        return request
    }
}

/// Related status info for quote or reblog. Reduced from `StatusInfo`, doesn't need to be recursive.
struct RelatedStatusInfo: Codable, Hashable, FetchableRecord {
    let record: StatusRecord
    let accountInfo: AccountInfo
    let relationship: Relationship?
    let showContentToggle: StatusShowContentToggle?
    let showAttachmentsToggle: StatusShowAttachmentsToggle?
    let showFilteredToggle: StatusShowFilteredToggle?
    let filtered: StatusFiltered?
}

extension RelatedStatusInfo {
    static func addingIncludes<T: DerivableRequest>(
        _ request: T,
        _ filterContext: Filter.Context?
    ) -> T where T.RowDecoder == StatusRecord {
        var request = request
            // Hack, change next line once GRDB supports chaining a required association behind an optional association
            .including(optional: AccountInfo.addingIncludes(StatusRecord.account).forKey(CodingKeys.accountInfo))
            .including(optional: StatusRecord.relationship.forKey(CodingKeys.relationship))
            .including(optional: StatusRecord.showContentToggle.forKey(CodingKeys.showContentToggle))
            .including(optional: StatusRecord.showAttachmentsToggle.forKey(CodingKeys.showAttachmentsToggle))
            .including(optional: StatusRecord.showFilteredToggle.forKey(CodingKeys.showFilteredToggle))
        if let filterContext = filterContext {
            request = request.including(optional: StatusRecord.filtered(filterContext).forKey(CodingKeys.filtered))
        }
        return request
    }
}
