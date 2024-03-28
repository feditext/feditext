// Copyright © 2024 Vyr Cossont. All rights reserved.

import MastodonAPI
import ServiceLayer
import SwiftUI

extension AnnotatedAPIError: DisplayableToastableError {
    func localizedStringKey(_ statusWord: AppPreferences.StatusWord) -> LocalizedStringKey? {
        if case let .notFound(what) = specialCase {
            switch what {
            case .account:
                return "toast.title.not-found.account"
            case .announcement:
                return "toast.title.not-found.announcement"
            case .attachment:
                return "toast.title.not-found.attachment"
            case .conversation:
                return "toast.title.not-found.conversation"
            case .featuredTag:
                return "toast.title.not-found.featured-tag"
            case .filter:
                return "toast.title.not-found.filter"
            case .list:
                return "toast.title.not-found.list"
            case .notification:
                return "toast.title.not-found.notification"
            case .poll:
                return "toast.title.not-found.poll"
            case .report:
                return "toast.title.not-found.report"
            case .rule:
                return "toast.title.not-found.rule"
            case .status:
                switch statusWord {
                case .post:
                    return "toast.title.not-found.status.post"
                case .toot:
                    return "toast.title.not-found.status.toot"
                }
            case .tag:
                return "toast.title.not-found.tag"
            }
        }
        return nil
    }

    func accessibilityTitle(_ statusWord: ServiceLayer.AppPreferences.StatusWord) -> String? {
        if case let .notFound(what) = specialCase {
            switch what {
            case .account:
                return NSLocalizedString("toast.title.not-found.account", comment: "")
            case .announcement:
                return NSLocalizedString("toast.title.not-found.announcement", comment: "")
            case .attachment:
                return NSLocalizedString("toast.title.not-found.attachment", comment: "")
            case .conversation:
                return NSLocalizedString("toast.title.not-found.conversation", comment: "")
            case .featuredTag:
                return NSLocalizedString("toast.title.not-found.featured-tag", comment: "")
            case .filter:
                return NSLocalizedString("toast.title.not-found.filter", comment: "")
            case .list:
                return NSLocalizedString("toast.title.not-found.list", comment: "")
            case .notification:
                return NSLocalizedString("toast.title.not-found.notification", comment: "")
            case .poll:
                return NSLocalizedString("toast.title.not-found.poll", comment: "")
            case .report:
                return NSLocalizedString("toast.title.not-found.report", comment: "")
            case .rule:
                return NSLocalizedString("toast.title.not-found.rule", comment: "")
            case .status:
                switch statusWord {
                case .post:
                    return NSLocalizedString("toast.title.not-found.status.post", comment: "")
                case .toot:
                    return NSLocalizedString("toast.title.not-found.status.toot", comment: "")
                }
            case .tag:
                return NSLocalizedString("toast.title.not-found.tag", comment: "")
            }
        }
        return nil
    }

    var systemImageName: String? {
        if case .notFound = specialCase {
            return "questionmark.circle"
        }
        return nil
    }
}
