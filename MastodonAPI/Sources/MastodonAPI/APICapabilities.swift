// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon
import Semver

/// Capabilities of the exact server we're talking to, taking into account API flavor and version.
public struct APICapabilities: Codable, Sendable {
    public let flavor: APIFlavor?
    public let version: Semver?
    public var features: Set<APIFeature>
    public var compatibilityMode: APICompatibilityMode?

    public init(
        flavor: APIFlavor? = nil,
        version: Semver? = nil,
        features: Set<APIFeature> = Set(),
        compatibilityMode: APICompatibilityMode? = nil
    ) {
        self.flavor = flavor
        self.version = version
        self.features = features
        self.compatibilityMode = compatibilityMode
    }

    /// Init from the mandatory software object of a NodeInfo doc.
    public init(nodeinfoSoftware: NodeInfo.Software) {
        // The space split is there mostly to handle GtS versions before this patch:
        // https://github.com/superseriousbusiness/gotosocial/pull/2611
        let version = nodeinfoSoftware.version
            .split(separator: " ", maxSplits: 1)
            .first
            .flatMap { Semver(String($0)) ?? Self.relaxedSemver($0) }

        var flavor = APIFlavor(rawValue: nodeinfoSoftware.name)
        // Detect known forks of Glitch, which doesn't use its own software name.
        if flavor == .mastodon,
           nodeinfoSoftware.version.contains("glitch") || nodeinfoSoftware.version.contains("chuckya") {
            flavor = .glitch
        }

        self.init(
            flavor: flavor,
            version: version
        )
    }

    /// Init from a NodeInfo doc.
    public init(nodeInfo: NodeInfo) {
        self.init(nodeinfoSoftware: nodeInfo.software)
    }

    /// For a few cases where we're using something so basic that every implementation has it.
    public static let unknown: Self = .init()

    /// Detect features from a given instance.
    public mutating func setDetectedFeatures(_ instance: Instance) {
        features = .init()

        if instance.configuration?.reactions != nil {
            features.insert(.emojiReactions)
        }
    }

    /// Pull the first three numbers off the front and hope it's good enough.
    private static func relaxedSemver(_ s: Substring) -> Semver {
        let trimmed: Substring
        if #available(iOS 16.0, macOS 13.0, *) {
            trimmed = s.trimmingPrefix("v")
        } else {
            trimmed = s.drop(while: { $0 == "v" })
        }

        let leadingNumericComponents = trimmed
            .split(maxSplits: 3, whereSeparator: { !$0.isNumber })
            .prefix(3)
            .compactMap { Int.init($0) }

        var major = 0
        if leadingNumericComponents.count > 0 {
            major = leadingNumericComponents[0]
        }

        var minor = 0
        if leadingNumericComponents.count > 1 {
            minor = leadingNumericComponents[1]
        }

        var patch = 0
        if leadingNumericComponents.count > 2 {
            patch = leadingNumericComponents[2]
        }

        return Semver(major: major, minor: minor, patch: patch)
    }
}

/// Features detected through the instance API.
public enum APIFeature: String, Codable, Sendable {
    /// Has Glitch PR #2221 compatible emoji reactions.
    case emojiReactions
}

/// Requirements to make an API call.
public struct APICapabilityRequirements {
    private let minVersions: [APIFlavor: Semver]
    private let requiredFeatures: Set<APIFeature>

    /// Does the given server's capabilities match our requirements?
    /// Features take higher priority than version detection: if we know that a feature is supported, go with that.
    /// Assume that, if we don't have a minimum version for a given flavor, that flavor is *not* supported.
    public func satisfiedBy(_ apiCapabilities: APICapabilities) -> Bool {
        if !requiredFeatures.isEmpty {
            if apiCapabilities.features.isSuperset(of: requiredFeatures) {
                return true
            }
        }

        guard let flavor = apiCapabilities.flavor,
              let version = apiCapabilities.version,
              let minVersion = minVersions[flavor] else {
            return false
        }
        return version >= minVersion
    }

    public static func | (lhs: Self, rhs: Self) -> Self {
        self.init(
            minVersions: lhs.minVersions.merging(rhs.minVersions, uniquingKeysWith: { $1 }),
            requiredFeatures: lhs.requiredFeatures.union(rhs.requiredFeatures)
        )
    }

    /// Set min versions for all Mastodon forks that closely track it.
    /// - Note: Fedibird uses its own versioning scheme in NodeInfo.
    public static func mastodonForks(_ minVersion: Semver) -> Self {
        return [
            .mastodon: minVersion,
            .glitch: minVersion,
            .hometown: minVersion
        ]
    }

    /// Require detected features instead of minimum versions.
    public static func features(_ features: APIFeature...) -> Self {
        self.init(
            minVersions: [:],
            requiredFeatures: Set(features)
        )
    }

}

extension APICapabilityRequirements: ExpressibleByDictionaryLiteral {
    public typealias Key = APIFlavor
    public typealias Value = Semver

    public init(dictionaryLiteral elements: (APIFlavor, Semver)...) {
        minVersions = .init(uniqueKeysWithValues: elements)
        requiredFeatures = .init()
    }
}

public extension Semver {
    /// We don't know which version added this, but assume it's available.
    static let assumeAvailable: Semver = "0.0.0"
}

/// All `Semver` fields are `Int` or `String` so this is safe.
extension Semver: @unchecked Sendable {}
