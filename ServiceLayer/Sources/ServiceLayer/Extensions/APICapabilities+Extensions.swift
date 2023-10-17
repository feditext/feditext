// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import CombineInterop
import Foundation
import Mastodon
import MastodonAPI
import Secrets

extension APICapabilities {
    /// Get API capabilities from NodeInfo and instance APIs, and as a side effect, store them in the secret store.
    /// (They're not secret, but that's where we keep other rarely changing values needed by the API client,
    /// like the instance URL.)
    static func refresh(
        session: URLSession,
        instanceURL: URL,
        secrets: Secrets
    ) async throws -> APICapabilities {
        let nodeInfoClient = try NodeInfoClient(session: session, instanceURL: instanceURL)
        let nodeInfo = try await nodeInfoClient.nodeInfo()
        var apiCapabilities = APICapabilities(nodeInfo: nodeInfo)

        apiCapabilities.compatibilityMode = secrets.getAPICompatibilityMode()

        let mastodonAPIClient = try MastodonAPIClient(
            session: session,
            instanceURL: instanceURL,
            apiCapabilities: apiCapabilities,
            accessToken: nil
        )
        let instance = try await mastodonAPIClient.request(InstanceEndpoint.instance)
        apiCapabilities.setDetectedFeatures(instance)

        try secrets.setAPICapabilities(apiCapabilities)
        return apiCapabilities
    }

    static func refresh(
        session: URLSession,
        instanceURL: URL,
        secrets: Secrets
    ) -> AnyPublisher<APICapabilities, Error> {
        Future {
            try await Self.refresh(session: session, instanceURL: instanceURL, secrets: secrets)
        }
        .eraseToAnyPublisher()
    }
}
