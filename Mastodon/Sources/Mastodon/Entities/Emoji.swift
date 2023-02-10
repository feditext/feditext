// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Emoji: Codable {
    public let shortcode: String
    public let staticUrl: UnicodeURL
    public let url: UnicodeURL
    public let visibleInPicker: Bool
    public let category: String?
}

extension Emoji: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(shortcode)
    }
}
