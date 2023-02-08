// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Mastodon
import SwiftUI
import ViewModels

struct PreferencesView: View {
    @StateObject var viewModel: PreferencesViewModel

    init(viewModel: PreferencesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            UserPreferencesSection(viewModel: viewModel)
            AppPreferencesSection(viewModel: viewModel, identityContext: viewModel.identityContext)
        }
        .navigationTitle("preferences")
        .alertItem($viewModel.alertItem)
        .onReceive(NotificationCenter.default.publisher(
                    for: UIAccessibility.videoAutoplayStatusDidChangeNotification)) { _ in
            viewModel.objectWillChange.send()
        }
    }
}

extension AppPreferences.ColorScheme {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .system:
            return "preferences.app.color-scheme.system"
        case .light:
            return "preferences.app.color-scheme.light"
        case .dark:
            return "preferences.app.color-scheme.dark"
        }
    }
}

extension AppPreferences.StatusWord {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .toot:
            return "toot.noun"
        case .post:
            return "post.noun"
        }
    }
}

extension AppPreferences.AnimateAvatars {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .everywhere:
            return "preferences.media.avatars.animate.everywhere"
        case .profiles:
            return "preferences.media.avatars.animate.profiles"
        case .never:
            return "preferences.media.avatars.animate.never"
        }
    }
}

extension AppPreferences.KeyboardType {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .twitter:
            return "preferences.keyboard-type.twitter"
        case .defaultText:
            return "preferences.keyboard-type.default-text"
        }
    }
}

extension AppPreferences.Autoplay {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .always:
            return "preferences.media.autoplay.always"
        case .wifi:
            return "preferences.media.autoplay.wifi"
        case .never:
            return "preferences.media.autoplay.never"
        }
    }
}

extension AppPreferences.PositionBehavior {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .localRememberPosition:
            return "preferences.position.remember-position"
        case .newest:
            return "preferences.position.newest"
        }
    }
}

#if DEBUG
import PreviewViewModels

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(viewModel: .init(identityContext: .preview))
    }
}
#endif
