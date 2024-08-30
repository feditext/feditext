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
        let accessToken: String?
        do {
            accessToken = try secrets.getAccessToken()
        } catch {
            // Unauthenticated identities (used for browsing instances with public APIs) don't have access tokens.
            // A Mastodon instance in allow-list federation mode won't have one the first time we do this,
            // but will once we've authenticated.
            accessToken = nil
        }

        let mastodonAPIClient = try MastodonAPIClient(
            session: session,
            instanceURL: instanceURL,
            apiCapabilities: apiCapabilities,
            accessToken: accessToken
        )
        do {
            let instance = try await mastodonAPIClient.request(InstanceEndpoint.instance)
            apiCapabilities.setDetectedFeatures(instance)
        } catch let e as SpecialCaseError where e.specialCase == .authRequired {
            // Occurs when trying to log into a Mastodon instance in allow-list federation mode.
            // (Does not affect GotoSocial in allow-list federation mode, since its instance API is still available.)
            // It's safe to ignore this for now, since we'll refresh capabilities again when we authenticate.
        }

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
