// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Represents a status's source as plain text.
/// https://docs.joinmastodon.org/entities/StatusSource/
public final class StatusSource: Codable, Identifiable {
    public let id: Status.Id
    public let text: String
    public let spoilerText: String

    public init(
        id: Status.Id,
        text: String,
        spoilerText: String
    ) {
        self.id = id
        self.text = text
        self.spoilerText = spoilerText
    }
}

extension StatusSource: Hashable {
    public static func == (lhs: StatusSource, rhs: StatusSource) -> Bool {
        lhs.id == rhs.id
            && lhs.text == rhs.text
            && lhs.spoilerText == rhs.spoilerText
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(text)
        hasher.combine(spoilerText)
    }
}
