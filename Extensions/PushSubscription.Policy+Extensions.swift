// Copyright © 2023 Vyr Cossont. All rights reserved.

import Mastodon
import SwiftUI

extension PushSubscription.Policy {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .all:
            return "preferences.notification-policy.all"
        case .followed:
            return "preferences.notification-policy.followed"
        case .follower:
            return "preferences.notification-policy.follower"
        case .none:
            return "preferences.notification-policy.none"
        case .unknown:
            return ""
        }
    }
}
