// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Relationship: Codable {
    public let id: Account.Id
    public let following: Bool
    public let requested: Bool
    @DecodableDefault.False public private(set) var endorsed: Bool
    public let followedBy: Bool
    public let muting: Bool
    @DecodableDefault.False public private(set) var mutingNotifications: Bool
    @DecodableDefault.False public private(set) var showingReblogs: Bool
    public let notifying: Bool?
    public let blocking: Bool
    // So far Pixelfed is the only implementation not to send this.
    @DecodableDefault.False public private(set) var domainBlocking: Bool
    @DecodableDefault.False public private(set) var blockedBy: Bool
    @DecodableDefault.EmptyString public private(set) var note: String
}

extension Relationship: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
