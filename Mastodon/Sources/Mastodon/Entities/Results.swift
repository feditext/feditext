// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Results: Codable {
    public let accounts: [Account]
    public let statuses: [Status]
    public let hashtags: [Tag]
}

public extension Results {
    static let empty = Self(accounts: [], statuses: [], hashtags: [])

    var isEmpty: Bool {
        accounts.isEmpty && statuses.isEmpty && hashtags.isEmpty
    }

    var count: Int {
        accounts.count + statuses.count + hashtags.count
    }

    /// Search results may contain duplicate entries if there are bugs.
    /// This will result in a crash when the search results table gets multiple cells with the same ID,
    /// so we need to dedupe results before using them for that.
    func dedupe() -> Self {
        return Self(
            accounts: accounts.dedupe(),
            statuses: statuses.dedupe(),
            hashtags: hashtags.dedupe()
        )
    }

    func appending(_ results: Self) -> Self {
        return Self(
            accounts: accounts + results.accounts,
            statuses: statuses + results.statuses,
            hashtags: hashtags + results.hashtags
        )
        .dedupe()
    }
}

extension Array where Element: Identifiable {
    /// De-duplicate a list with ``Identifiable`` elements, preserving order.
    func dedupe() -> Self {
        var ids = Set<Element.ID>()
        var deduped = [Element]()
        for element in self where !ids.contains(element.id) {
            deduped.append(element)
            ids.insert(element.id)
        }
        return deduped
    }
}
