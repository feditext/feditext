// Copyright © 2024 Vyr Cossont. All rights reserved.

import MastodonAPI

extension AnnotatedAPIError: ToastableError {
    public var toastable: Bool {
        switch specialCase {
        case .notFound:
            return true
        default:
            return false
        }
    }
}
