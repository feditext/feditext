// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Report: Codable {
    public let id: Id
    public let actionTaken: Bool

    public init(
        id: Id,
        actionTaken: Bool
    ) {
        self.id = id
        self.actionTaken = actionTaken
    }
}

public extension Report {
    typealias Id = String
}

extension Report: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
