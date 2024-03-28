// Copyright © 2024 Vyr Cossont. All rights reserved.

import ServiceLayer
import SwiftUI
import ViewModels

/// SwiftUI-specific stuff for displaying alert toasts.
extension AlertItem {
    func localizedStringKey(_ statusWord: AppPreferences.StatusWord) -> LocalizedStringKey? {
        if let toastable = error as? DisplayableToastableError {
            return toastable.localizedStringKey(statusWord)
        }
        return nil
    }

    func accessibilityTitle(_ statusWord: AppPreferences.StatusWord) -> String? {
        if let toastable = error as? DisplayableToastableError {
            return toastable.accessibilityTitle(statusWord)
        }
        return nil
    }

    var systemImageName: String? {
        if let toastable = error as? DisplayableToastableError {
            return toastable.systemImageName
        }
        return nil
    }
}

/// An event with a toast case.
public protocol ToastableEvent {
    static func toast(_ alertItem: AlertItem) -> Self
}

/// Toastable error with a localized message and icon used when displaying it.
protocol DisplayableToastableError: Error {
    func localizedStringKey(_ statusWord: AppPreferences.StatusWord) -> LocalizedStringKey?
    func accessibilityTitle(_ statusWord: AppPreferences.StatusWord) -> String?
    var systemImageName: String? { get }
}
