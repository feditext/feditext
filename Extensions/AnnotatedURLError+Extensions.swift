// Copyright © 2024 Vyr Cossont. All rights reserved.

import HTTP
import ServiceLayer
import SwiftUI

extension AnnotatedURLError: DisplayableToastableError {
    func localizedStringKey(_ statusWord: AppPreferences.StatusWord) -> LocalizedStringKey? {
        switch name {
        case .cannotFindHost,
                .cannotConnectToHost,
                .dnsLookupFailed,
                .redirectToNonExistentLocation:
            return "toast.title.not-found.server"
        case .networkConnectionLost,
                .notConnectedToInternet,
                .callIsActive,
                .dataNotAllowed,
                .internationalRoamingOff:
            return "toast.title.no-internet-connection"
        default:
            return nil
        }
    }

    func accessibilityTitle(_ statusWord: AppPreferences.StatusWord) -> String? {
        switch name {
        case .cannotFindHost,
                .cannotConnectToHost,
                .dnsLookupFailed,
                .redirectToNonExistentLocation:
            return NSLocalizedString("toast.title.not-found.server", comment: "")
        case .networkConnectionLost,
                .notConnectedToInternet,
                .callIsActive,
                .dataNotAllowed,
                .internationalRoamingOff:
            return NSLocalizedString("toast.title.no-internet-connection", comment: "")
        default:
            return nil
        }
    }

    var systemImageName: String? {
        switch name {
        case .cannotFindHost,
                .cannotConnectToHost,
                .dnsLookupFailed,
                .redirectToNonExistentLocation:
            return "questionmark.circle"
        case .networkConnectionLost,
                .notConnectedToInternet,
                .callIsActive,
                .dataNotAllowed,
                .internationalRoamingOff:
            return "network.slash"
        default:
            return nil
        }
    }
}
