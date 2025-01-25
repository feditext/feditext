// Copyright © 2024 Vyr Cossont. All rights reserved.

/// Mastodon Web Push notification IDs are actual integers, but other implementations use strings.
@propertyWrapper
public struct PushNotificationID: Hashable {
    public var wrappedValue: String

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }
}

extension PushNotificationID: Decodable {
    /// Decode from string or int.
    public init(from decoder: Decoder) throws {
        do {
            wrappedValue = try decoder.singleValueContainer().decode(String.self)
        } catch {
            wrappedValue = String(try decoder.singleValueContainer().decode(Int.self))
        }
    }
}

extension PushNotificationID: Encodable {
    /// Always encode to string.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(wrappedValue))
    }
}
