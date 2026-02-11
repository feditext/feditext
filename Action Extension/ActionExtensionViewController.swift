// Copyright © 2022 Metabolist. All rights reserved.

import AppUrls
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

/// Let the user open a URL that might be an ActivityPub actor or activity in the app.
/// Should activate for one or more web URLs, but will only do anything with the first..
class ActionExtensionViewController: UIViewController {
  /// Extensions aren't allowed to call `UIApplication.shared
  ///  and thus don't have direct access to its `open` method.
  /// As a workaround, we find `UIApplication` in the responder chain.
  /// It's cursed, but it uses public APIs and works.
  private func open(url: URL) {
    var responder: UIResponder? = self as UIResponder
    while responder != nil {
      if let application = responder as? UIApplication {
        application.open(url)
        return
      }
      responder = responder?.next
    }
  }

  /// This extension has no actual UI, so we act on extension input items as soon as we load.
  override func viewDidLoad() {
    super.viewDidLoad()

    // Find the first URL or thing coerceable to a URL.
    for item in self.extensionContext!.inputItems as? [NSExtensionItem] ?? [] {
      for provider in item.attachments! where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
        _ = provider.loadObject(ofClass: URL.self) { (url, error) in
          OperationQueue.main.addOperation {
            if let error = error {
              self.extensionContext!.cancelRequest(withError: error)
            } else if let url = url {
              // Create a `feditext:search?url=https…` URL from our web URL.
              self.open(url: AppUrl.search(url).url)
              self.extensionContext!.completeRequest(returningItems: [])
            } else {
              // Should never happen. Return a generic not-found error.
              self.extensionContext!.cancelRequest(withError: CocoaError(.fileNoSuchFile))
            }
          }
        }
        // We do not attempt to handle multiple URLs.
        return
      }
    }
    // No URLs. Return a generic not-found error.
    self.extensionContext!.cancelRequest(withError: CocoaError(.fileNoSuchFile))
  }
}
