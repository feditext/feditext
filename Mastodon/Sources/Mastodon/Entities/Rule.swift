// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// A server rule.
public struct Rule: Codable, Identifiable, Equatable {
    public typealias Id = String

    public let id: Id
    public let text: String

    public init(id: Id, text: String) {
        self.id = id
        self.text = text
    }
}

extension Rule: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
