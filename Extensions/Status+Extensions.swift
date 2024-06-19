// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import MastodonAPI
import UIKit

extension Status.Visibility {
    var systemImageName: String {
        switch self {
        case .public:
            return "network"
        case .unlisted:
            return "lock.open"
        case .private:
            return "lock"
        case .mutualsOnly:
            return "arrow.left.arrow.right"
        case .direct:
            return "envelope"
        case .unknown:
            return "questionmark"
        }
    }

    var systemImageNameForVisibilityIconColors: String {
        switch self {
        case .unlisted:
            return "lock.open.fill"
        case .private:
            return "lock.fill"
        case .mutualsOnly:
            return "arrow.left.arrow.right.square.fill"
        case .direct:
            return "envelope.fill"
        default:
            return systemImageName
        }
    }

    var tintColor: UIColor? {
        switch self {
        case .public:
            return .systemBlue
        case .unlisted:
            return .systemGreen
        case .private, .mutualsOnly:
            return .systemYellow
        case .direct:
            return .systemRed
        case .unknown:
            return nil
        }
    }

    var title: String? {
        switch self {
        case .public:
            return NSLocalizedString("status.visibility.public", comment: "")
        case .unlisted:
            return NSLocalizedString("status.visibility.unlisted", comment: "")
        case .private:
            return NSLocalizedString("status.visibility.private", comment: "")
        case .mutualsOnly:
            return NSLocalizedString("status.visibility.mutuals-only", comment: "")
        case .direct:
            return NSLocalizedString("status.visibility.direct", comment: "")
        case .unknown:
            return nil
        }
    }

    var description: String? {
        switch self {
        case .public:
            return NSLocalizedString("status.visibility.public.description", comment: "")
        case .unlisted:
            return NSLocalizedString("status.visibility.unlisted.description", comment: "")
        case .private:
            return NSLocalizedString("status.visibility.private.description", comment: "")
        case .mutualsOnly:
            return NSLocalizedString("status.visibility.mutuals-only.description", comment: "")
        case .direct:
            return NSLocalizedString("status.visibility.direct.description", comment: "")
        case .unknown:
            return nil
        }
    }

    static func allSupportedCases(_ apiCapabilities: APICapabilities) -> [Self] {
        Self.allCasesExceptUnknown.filter { visibility in
            StatusEndpoint.post(.init(
                inReplyToId: nil,
                text: "",
                spoilerText: "",
                mediaIds: [],
                visibility: visibility,
                language: nil,
                sensitive: false,
                pollOptions: [],
                pollExpiresIn: 0,
                pollMultipleChoice: false,
                federated: nil,
                boostable: nil,
                replyable: nil,
                likeable: nil
            ))
            .canCallWith(apiCapabilities)
        }
    }
}
