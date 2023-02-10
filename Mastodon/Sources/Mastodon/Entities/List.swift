// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct List: Codable, Identifiable {
    public let id: Id
    public let title: String

    public init(id: Id, title: String) {
        self.id = id
        self.title = title
    }
}

public extension List {
    typealias Id = String
}

extension List: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
