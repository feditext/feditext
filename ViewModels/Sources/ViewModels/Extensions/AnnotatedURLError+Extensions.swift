// Copyright © 2024 Vyr Cossont. All rights reserved.

import HTTP

extension AnnotatedURLError: ToastableError {
    public var toastable: Bool {
        switch name {
        case .cannotFindHost,
                .cannotConnectToHost,
                .dnsLookupFailed,
                .redirectToNonExistentLocation,
                .networkConnectionLost,
                .notConnectedToInternet,
                .callIsActive,
                .dataNotAllowed,
                .internationalRoamingOff:
            return true
        default:
            return false
        }
    }
}
