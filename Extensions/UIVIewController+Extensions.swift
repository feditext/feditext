// Copyright © 2020 Metabolist. All rights reserved.

import SafariServices
import UIKit
import UniformTypeIdentifiers
import ViewModels

extension UIViewController {
    var isVisible: Bool { isViewLoaded && view.window != nil }

    func present(alertItem: AlertItem) {
        let copyActionTitle: String
        let copyItems: [String: Data]
        if let json = alertItem.json {
            copyActionTitle = NSLocalizedString("error.alert.copy-json", comment: "")
            copyItems = [
                UTType.json.identifier: json,
                // Intentional JSON as text: it's already pretty-printed and most apps can't handle a JSON paste.
                UTType.utf8PlainText.identifier: json
            ]
        } else {
            copyActionTitle = NSLocalizedString("error.alert.copy-text", comment: "")
            copyItems = [
                UTType.utf8PlainText.identifier: alertItem.text
            ]
        }

        let alertController = UIAlertController(
            title: alertItem.title,
            message: alertItem.message,
            preferredStyle: .alert)

        let copyAction = UIAlertAction(title: copyActionTitle, style: .default) { _ in
            UIPasteboard.general.setItems([copyItems])
        }
        alertController.addAction(copyAction)

        let okAction = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default) { _ in }
        alertController.addAction(okAction)
        alertController.preferredAction = okAction

        present(alertController, animated: true)
    }

    #if !IS_SHARE_EXTENSION
    func open(url: URL, identityContext: IdentityContext) {
        func openWithRegardToBrowserSetting(url: URL) {
            if identityContext.appPreferences.openLinksInDefaultBrowser || !url.isHTTPURL {
                UIApplication.shared.open(url)
            } else {
                let safariVC = SFSafariViewController(url: url)
                safariVC.preferredControlTintColor = view.tintColor
                present(safariVC, animated: true)
            }
        }

        if identityContext.appPreferences.useUniversalLinks {
            UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { success in
                if !success {
                    openWithRegardToBrowserSetting(url: url)
                }
            }
        } else {
            openWithRegardToBrowserSetting(url: url)
        }
    }
    #endif
}
