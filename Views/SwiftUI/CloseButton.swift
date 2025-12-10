// Copyright © 2023 Vyr Cossont. All rights reserved.

import SwiftUI
import UIKit

/// Embed a `UIButton.ButtonStyle.close` button in SwiftUI, which doesn't have that yet.
///
/// - See: https://stackoverflow.com/a/73629513
struct CloseButton: UIViewRepresentable {
  private let action: () -> Void

  init(action: @escaping () -> Void) { self.action = action }

  func makeUIView(context: Context) -> UIButton {
    UIButton(type: .close, primaryAction: UIAction { _ in action() })
  }

  func updateUIView(_ uiView: UIButton, context: Context) {}
}
