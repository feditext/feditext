// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension Filter: ContentDatabaseRecord {}

extension Filter {
    enum Columns: String, ColumnExpression {
        case id
        case phrase
        case context
        case expiresAt
        case irreversible
        case wholeWord
    }

    /// Return a v2 equivalent of this filter, for use only in constructing a client-side ``Status.FilterResult``.
    var v2: FilterV2 {
        .init(
            id: "",
            title: phrase,
            context: context,
            expiresAt: expiresAt,
            filterAction: irreversible ? .hide : .warn,
            keywords: [
                .init(id: "", keyword: phrase, wholeWord: wholeWord),
            ],
            statuses: []
        )
    }

    /// Compile this filter to a regex.
    var matcher: Matcher? {
        guard let regex = try? NSRegularExpression(pattern: regularExpression, options: .caseInsensitive) else {
            return nil
        }

        return .init(filter: self, regex: regex)
    }

    /// Apply a v1 filter and generate a v2 filter result if it matches.
    struct Matcher {
        let filter: Filter
        let regex: NSRegularExpression

        func match(_ statusInfo: StatusInfo, _ filterContext: Filter.Context, now: Date) -> Status.FilterResult? {
            guard filter.context.contains(filterContext) else {
                return nil
            }
            if let expiresAt = filter.expiresAt {
                if now >= expiresAt {
                    return nil
                }
            }

            let filterableContent = statusInfo.filterableContent
            let firstMatch = regex.firstMatch(in: filterableContent, range: .init(location: 0, length: filterableContent.count))
            if firstMatch == nil {
                return nil
            }

            return .init(filter: filter.v2, keywordMatches: [filter.phrase], statusMatches: [])
        }
    }
}

extension Array where Element == StatusInfo {
    /// Apply v1 filters and return v2-compatible results.
    func filtered(_ matchers: [Filter.Matcher], _ filterContext: Filter.Context?, now: Date) -> Self {
        guard let filterContext = filterContext, !matchers.isEmpty else { return self }

        return self.map { statusInfo in
            statusInfo.with(
                filtered: .init(
                    statusId: statusInfo.record.id,
                    context: filterContext,
                    filtered: matchers.compactMap { $0.match(statusInfo, filterContext, now: now) }
                )
            )
        }
    }
}

extension Filter.Context? {
    /// Single statuses don't have a filter context, only those retrieved from bulk APIs.
    public static var single: Self { nil }
    /// Search results don't have a filter context.
    public static var search: Self { nil }
    /// DM conversations don't have a filter context.
    public static var conversation: Self { nil }
}
