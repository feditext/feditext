// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
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
    ) -> AnyPublisher<APICapabilities, Error> {
        let nodeInfoClient: NodeInfoClient
        do {
            nodeInfoClient = try NodeInfoClient(session: session, instanceURL: instanceURL)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return nodeInfoClient
            .nodeInfo()
            .map(APICapabilities.init(nodeInfo:))
            .map { apiCapabilities in
                var apiCapabilities = apiCapabilities
                apiCapabilities.compatibilityMode = secrets.getAPICompatibilityMode()
                return apiCapabilities
            }
            .flatMap { apiCapabilities in
                Self.detectFeatures(
                    session: session,
                    instanceURL: instanceURL,
                    apiCapabilities: apiCapabilities
                )
            }
            .tryMap { apiCapabilities in
                try secrets.setAPICapabilities(apiCapabilities)
                return apiCapabilities
            }
            .eraseToAnyPublisher()
    }

    /// Add features detected from the instance API.
    private static func detectFeatures(
        session: URLSession,
        instanceURL: URL,
        apiCapabilities: APICapabilities
    ) -> AnyPublisher<APICapabilities, Error> {
        let mastodonAPIClient: MastodonAPIClient
        do {
            mastodonAPIClient = try MastodonAPIClient(
                session: session,
                instanceURL: instanceURL,
                apiCapabilities: apiCapabilities
            )
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return mastodonAPIClient
            .request(InstanceEndpoint.instance)
            .map { instance in
                var apiCapabilities = apiCapabilities
                apiCapabilities.setDetectedFeatures(instance)
                return apiCapabilities
            }
            .eraseToAnyPublisher()
    }
}
