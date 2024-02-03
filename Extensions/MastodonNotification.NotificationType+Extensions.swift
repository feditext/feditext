// Copyright © 2023 Vyr Cossont. All rights reserved.

import Mastodon
import SwiftUI

extension MastodonNotification.NotificationType {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .follow:
            return "preferences.notification-types.follow"
        case .mention:
            return "preferences.notification-types.mention"
        case .reblog:
            return "preferences.notification-types.reblog"
        case .favourite:
            return "preferences.notification-types.favourite"
        case .poll:
            return "preferences.notification-types.poll"
        case .followRequest:
            return "preferences.notification-types.follow-request"
        case .status:
            return "preferences.notification-types.status"
        case .update:
            return "preferences.notification-types.update"
        case .adminSignup:
            return "preferences.notification-types.admin-signup"
        case .adminReport:
            return "preferences.notification-types.admin-report"
        case .unknown:
            return ""
        }
    }

    var systemImageName: String {
        switch self {
        case .follow:
            return "person.fill.badge.plus"
        case .followRequest:
            return "person.fill.questionmark"
        case .mention:
            return "at"
        case .reblog:
            return "arrow.2.squarepath"
        case .favourite:
            return "star.fill"
        case .poll:
            return "chart.bar.xaxis"
        case .status:
            return "bell.fill"
        case .update:
            return "pencil.line"
        case .adminSignup:
            return "person.fill.viewfinder"
        case .adminReport:
            return "exclamationmark.bubble"
        case .unknown:
            return "app.badge"
        }
    }
}
