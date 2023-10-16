// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Overrides API capabilities detection.
public enum APICompatibilityMode: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    /// Attempt all calls. In the event of an error, substitute the endpoint's fallback data, if it exists.
    case fallbackOnErrors
    /// Attempt all calls. Allow failures.
    case failOnErrors

    public var id: Self { self }
}
