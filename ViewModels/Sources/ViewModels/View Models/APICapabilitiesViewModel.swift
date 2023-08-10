// Copyright © 2023 Vyr Cossont. All rights reserved.

import MastodonAPI
import SwiftUI

public struct APICapabilitiesViewModel {
    private let apiCapabilities: APICapabilities

    public init(apiCapabilities: APICapabilities) {
        self.apiCapabilities = apiCapabilities
    }

    public var localizedName: LocalizedStringKey? {
        switch apiCapabilities.flavor {
        case .none:
            return nil
        case .mastodon:
            return "flavor.mastodon.name"
        case .glitch:
            return "flavor.glitch.name"
        case .hometown:
            return "flavor.hometown.name"
        case .fedibird:
            return "flavor.fedibird.name"
        case .pleroma:
            return "flavor.pleroma.name"
        case .akkoma:
            return "flavor.akkoma.name"
        case .gotosocial:
            return "flavor.gotosocial.name"
        case .calckey:
            return "flavor.calckey.name"
        case .firefish:
            return "flavor.firefish.name"
        case .iceshrimp:
            return "flavor.iceshrimp.name"
        case .snac:
            return "flavor.snac.name"
        }
    }

    public var homepage: URL? {
        switch apiCapabilities.flavor {
        case .none:
            return nil
        case .mastodon:
            return URL(string: "https://joinmastodon.org/")
        case .glitch:
            return URL(string: "https://glitch-soc.github.io/docs/")
        case .hometown:
            return URL(string: "https://github.com/hometown-fork/hometown")
        case .fedibird:
            return URL(string: "https://fedibird.com/")
        case .pleroma:
            return URL(string: "https://pleroma.social/")
        case .akkoma:
            return URL(string: "https://akkoma.social/")
        case .gotosocial:
            return URL(string: "https://gotosocial.org/")
        case .calckey:
            return URL(string: "https://calckey.org/")
        case .firefish:
            return URL(string: "https://joinfirefish.org/")
        case .iceshrimp:
            return URL(string: "https://iceshrimp.dev/")
        case .snac:
            return URL(string: "https://codeberg.org/grunfink/snac2")
        }
    }

    public var version: String? { apiCapabilities.version?.description }
}
