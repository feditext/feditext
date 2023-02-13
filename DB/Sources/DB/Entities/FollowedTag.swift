// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import GRDB
import Mastodon

/// A followed hashtag. We only store the name.
public struct FollowedTag: ContentDatabaseRecord, Equatable {
    public let name: Tag.Name

    public init(name: Tag.Name) {
        self.name = name
    }
}

extension FollowedTag {
    enum Columns: String, ColumnExpression {
        case name
    }

    public init(_ tag: Tag) {
        self.init(name: tag.name)
    }
}

extension FollowedTag: Comparable {
    public static func < (lhs: FollowedTag, rhs: FollowedTag) -> Bool {
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}

extension FollowedTag: Identifiable {
    public typealias ObjectIdentifier = Tag.Name

    public var id: ObjectIdentifier { name }
}
