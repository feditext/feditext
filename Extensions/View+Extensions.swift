// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import ViewModels

extension View {
    func alertItem(_ alertItem: Binding<AlertItem?>) -> some View {
        alert(item: alertItem) {
            let copyButtonTitle: LocalizedStringKey
            let copyItems: [String: Data]
            if let json = $0.json {
                copyButtonTitle = "error.alert.copy-json"
                copyItems = [
                    UTType.json.identifier: json,
                    // Intentional JSON as text: it's already pretty-printed and most apps can't handle a JSON paste.
                    UTType.utf8PlainText.identifier: json
                ]
            } else {
                copyButtonTitle = "error.alert.copy-text"
                copyItems = [
                    UTType.utf8PlainText.identifier: $0.text
                ]
            }

            return Alert(
                title: Text($0.title),
                message: Text($0.message),
                primaryButton: .default(Text("ok")),
                secondaryButton: .default(Text(copyButtonTitle)) {
                    UIPasteboard.general.setItems([copyItems])
                }
            )
        }
    }
}

// MARK: - toasts

extension View {
    func toast(_ alertItem: Binding<AlertItem?>) -> some View {
        modifier(ToastViewModifier(alertItem: alertItem.animation()))
    }
}

/// Stacks a given view with a toast.
struct ToastViewModifier: ViewModifier {
    let alertItem: Binding<AlertItem?>
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion: Bool
    @Environment(\.statusWord) var statusWord: AppPreferences.StatusWord

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
                .zIndex(0)

            if let alertItem = alertItem.wrappedValue {
                ToastView(alertItem: alertItem) {
                    self.alertItem.wrappedValue = nil
                }
                .padding(.top, 48)
                .zIndex(1)
                .onTapGesture {
                    self.alertItem.wrappedValue = nil
                }
                .onAppear {
                    guard let alertItem = self.alertItem.wrappedValue else { return }

                    // Speak the toast title if there's a screen reader running.
                    let announcement: String = alertItem.accessibilityTitle(self.statusWord)
                        ?? alertItem.title
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: announcement as NSString
                    )

                    // Close the toast after 5 seconds.
                    Task {
                        do {
                            try await Task.sleep(nanoseconds: UInt64(5e9))
                        } catch {
                            // If we failed to sleep (is that even possible?), exit without closing the toast.
                            return
                        }
                        self.alertItem.wrappedValue = nil
                    }
                }
                .transition(
                    accessibilityReduceMotion
                        ? .identity
                        : .opacity.combined(with: .move(edge: .top))
                )
            }
        }
    }
}

/// The view that implements the toast itself.
struct ToastView: View {
    let alertItem: AlertItem
    let closeAction: () -> Void

    var body: some View {
        HStack {
            if let systemImageName = alertItem.systemImageName {
                Image(systemName: systemImageName)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.defaultSpacing)
            }

            VStack {
                if let localizedStringKey = alertItem.localizedStringKey(.toot) {
                    Text(localizedStringKey)
                        .lineLimit(1)
                        .font(.subheadline)
                } else {
                    Text(alertItem.title)
                        .lineLimit(1)
                        .font(.subheadline)

                    Text(alertItem.message)
                        .lineLimit(1)
                        .font(.footnote)
                }
            }

            CloseButton(action: closeAction)
                .aspectRatio(1, contentMode: .fit)
                .padding(.defaultSpacing)
        }
        .foregroundStyle(.secondary)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(radius: .defaultShadowRadius)
        .frame(width: 300, height: 50)
    }
}
