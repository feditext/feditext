// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import MastodonAPI
import os
import Secrets

extension Secrets {
    // TODO: (Vyr) permanent fix: don't use the keychain for anything read frequently
    private static let cache = NSCache<NSUUID, APICapabilitiesCacheValue>()

    func getAPICapabilities() -> APICapabilities {
        let key = identityId as NSUUID

        if let cached = Self.cache.object(forKey: key) {
            return cached.apiCapabilities
        }

        var apiCapabilities: APICapabilities
        do {
            apiCapabilities = .init(
                nodeinfoSoftware: .init(
                    name: try getSoftwareName(),
                    version: try getSoftwareVersion()
                )
            )
        } catch {
            // This should only happen with old versions of the secret store that predate NodeInfo detection.
            // In this case, it's okay to return a default; something will call refreshAPICapabilities soon.
            Logger().warning("API capabilities missing from Secrets, falling back to unknown capabilities")
            apiCapabilities = .init(
                nodeinfoSoftware: .init(
                    name: "",
                    version: ""
                )
            )
        }
        apiCapabilities.compatibilityMode = getAPICompatibilityMode()
        apiCapabilities.features = getAPIFeatures()

        Self.cache.setObject(.init(apiCapabilities: apiCapabilities), forKey: key)
        return apiCapabilities
    }

    func setAPICapabilities(_ apiCapabilities: APICapabilities) throws {
        Self.cache.removeObject(forKey: identityId as NSUUID)

        try setSoftwareName(apiCapabilities.flavor?.rawValue ?? "")
        try setSoftwareVersion(apiCapabilities.version?.description ?? "")
        try setAPIFeatures(apiCapabilities.features)
        try setAPICompatibilityMode(apiCapabilities.compatibilityMode)
    }

    func getAPIFeatures() -> Set<APIFeature> {
        do {
            return .init(try getAPIFeaturesRawValues().compactMap { APIFeature(rawValue: $0) })
        } catch {
            return .init()
        }
    }

    func setAPIFeatures(_ features: Set<APIFeature>) throws {
        Self.cache.removeObject(forKey: identityId as NSUUID)

        try setAPIFeaturesRawValues(features.map(\.rawValue))
    }

    func getAPICompatibilityMode() -> APICompatibilityMode? {
        do {
            return .init(rawValue: try getAPICompatibilityModeRawValue())
        } catch {
            return nil
        }
    }

    func setAPICompatibilityMode(_ apiCompatibilityMode: APICompatibilityMode?) throws {
        Self.cache.removeObject(forKey: identityId as NSUUID)

        try setAPICompatibilityModeRawValue(apiCompatibilityMode?.rawValue ?? "")
    }
}

private class APICapabilitiesCacheValue {
    let apiCapabilities: APICapabilities

    init(apiCapabilities: APICapabilities) {
        self.apiCapabilities = apiCapabilities
    }
}
