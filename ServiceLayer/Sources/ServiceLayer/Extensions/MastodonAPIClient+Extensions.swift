// Copyright © 2021 Metabolist. All rights reserved.

import MastodonAPI
import Secrets

extension MastodonAPIClient {
    static func forIdentity(id: Identity.Id, environment: AppEnvironment) throws -> Self {
        let secrets = Secrets(identityId: id, keychain: environment.keychain)

        let client = try Self(
            session: environment.session,
            instanceURL: try secrets.getInstanceURL(),
            apiCapabilities: secrets.getAPICapabilities(),
            accessToken: try secrets.getAccessToken()
        )

        return client
    }

    var supportsV2Filters: Bool { FiltersV2Endpoint.filters.canCallWith(apiCapabilities) }
}
