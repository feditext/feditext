// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Report: Codable {
    public enum Category: String, Codable, Unknowable, Identifiable {
        case violation
        case spam
        case other
        case unknown

        public static var unknownCase: Self { .unknown }

        public typealias ObjectIdentifier = Self
        public var id: ObjectIdentifier { self }
    }

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
