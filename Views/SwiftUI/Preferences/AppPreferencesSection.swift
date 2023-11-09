// Copyright © 2020 Metabolist. All rights reserved.

import AppMetadata
import Foundation
import Mastodon
import MastodonAPI
import SwiftUI
import ViewModels

/// App-wide preferences.
struct AppPreferencesSection: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @ObservedObject var identityContext: IdentityContext
    @EnvironmentObject var rootViewModel: RootViewModel

    @State var apiCompatibilityModeChanged: Bool = false

    var body: some View {
        Section(header: Text("preferences.app")) {
            Group {
                if UIApplication.shared.supportsAlternateIcons {
                    NavigationLink(destination: AppIconPreferencesView(viewModel: viewModel)) {
                        HStack {
                            Text("preferences.app-icon")
                            Spacer()
                            if let appIcon = AppIcon.current {
                                if let image = appIcon.image {
                                    image
                                        .resizable()
                                        .frame(
                                            width: UIFont.preferredFont(forTextStyle: .body).lineHeight,
                                            height: UIFont.preferredFont(forTextStyle: .body).lineHeight)
                                        .cornerRadius(.defaultCornerRadius / 2)
                                }
                                Text(appIcon.nameLocalizedStringKey)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                Picker("preferences.app.color-scheme", selection: $identityContext.appPreferences.colorScheme) {
                    ForEach(AppPreferences.ColorScheme.allCases) { option in
                        Text(option.localizedStringKey).tag(option)
                    }
                }
                NavigationLink("preferences.notifications.display-and-sounds",
                               destination: NotificationPreferencesView(viewModel: viewModel))
                Picker("preferences.status-word",
                       selection: $identityContext.appPreferences.statusWord) {
                    ForEach(AppPreferences.StatusWord.allCases) { option in
                        Text(option.localizedStringKey).tag(option)
                    }
                }
                Picker("preferences.keyboard-type",
                       selection: $identityContext.appPreferences.keyboardType) {
                    ForEach(AppPreferences.KeyboardType.allCases) { option in
                        Text(option.localizedStringKey).tag(option)
                    }
                }
                NavigationLink("preferences.posting-languages") {
                    PostingLanguagesView(
                        postingLanguages: $identityContext.appPreferences.postingLanguages
                    )
                }
                Group {
                    Toggle("preferences.use-media-description-metadata",
                           isOn: $identityContext.appPreferences.useMediaDescriptionMetadata)
                    Toggle("preferences.show-reblog-and-favorite-counts",
                           isOn: $identityContext.appPreferences.showReblogAndFavoriteCounts)
                    Toggle("preferences.require-double-tap-to-reblog",
                           isOn: $identityContext.appPreferences.requireDoubleTapToReblog)
                    Toggle("preferences.require-double-tap-to-favorite",
                           isOn: $identityContext.appPreferences.requireDoubleTapToFavorite)
                    Toggle("preferences.links.open-in-default-browser",
                           isOn: $identityContext.appPreferences.openLinksInDefaultBrowser)
                    if !identityContext.appPreferences.openLinksInDefaultBrowser {
                        Toggle("preferences.links.use-universal-links",
                               isOn: $identityContext.appPreferences.useUniversalLinks)
                    }
                }
            }
            Group {
                Picker("preferences.media.autoplay.gifs",
                       selection: $identityContext.appPreferences.autoplayGIFs) {
                    ForEach(AppPreferences.Autoplay.allCases) { option in
                        Text(option.localizedStringKey).tag(option)
                    }
                }
                Picker("preferences.media.autoplay.videos",
                       selection: $identityContext.appPreferences.autoplayVideos) {
                    ForEach(AppPreferences.Autoplay.allCases) { option in
                        Text(option.localizedStringKey).tag(option)
                    }
                }
                Picker("preferences.media.avatars.animate",
                       selection: $identityContext.appPreferences.animateAvatars) {
                    ForEach(AppPreferences.AnimateAvatars.allCases) { option in
                        Text(option.localizedStringKey).tag(option)
                    }
                }
                Toggle("preferences.media.custom-emojis.animate",
                       isOn: $identityContext.appPreferences.animateCustomEmojis)
                Toggle("preferences.media.headers.animate",
                       isOn: $identityContext.appPreferences.animateHeaders)
                Toggle("preferences.hide-content-warning-button",
                       isOn: $identityContext.appPreferences.hideContentWarningButton)
                Toggle("preferences.long-content.fold",
                       isOn: $identityContext.appPreferences.foldLongPosts)
                Toggle("preferences.trailing-hashtags.fold",
                       isOn: $identityContext.appPreferences.foldTrailingHashtags)
            }
            Group {
                Toggle("preferences.visibility-icon-colors",
                       isOn: $identityContext.appPreferences.visibilityIconColors)
                HStack {
                    Text("preferences.visibility-icon-colors.off")
                    ForEach(Status.Visibility.allCasesExceptUnknown) { visibility in
                        Image(systemName: visibility.systemImageName)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }

                    Spacer()

                    Text("preferences.visibility-icon-colors.on")
                    ForEach(Status.Visibility.allCasesExceptUnknown) { visibility in
                        Image(systemName: visibility.systemImageNameForVisibilityIconColors)
                            .renderingMode(.template)
                            .foregroundColor(visibility.tintColor.map(Color.init(uiColor:)))
                    }
                }
            }
            if viewModel.identityContext.identity.authenticated
                && !viewModel.identityContext.identity.pending {
                Picker("preferences.home-timeline-position-on-startup",
                       selection: $identityContext.appPreferences.homeTimelineBehavior) {
                    ForEach(AppPreferences.PositionBehavior.allCases) { option in
                        Text(option.localizedStringKey).tag(option)
                    }
                }
            }
        }
        Section(header: Text("preferences.app.advanced")) {
            Picker("preferences.api-compatibility-mode", selection: Binding<APICompatibilityMode?>(
                get: { identityContext.getAPICompatibilityMode() },
                set: {
                    do {
                        try identityContext.setAPICompatibilityMode($0)
                        apiCompatibilityModeChanged = true
                    } catch {
                        viewModel.alertItem = .init(error: error)
                    }
                }
            )) {
                Text("preferences.api-compatibility-mode.off").tag(Optional<APICompatibilityMode>.none)
                ForEach(APICompatibilityMode.allCases) { apiCompatibilityMode in
                    Text(apiCompatibilityMode.localizedStringKey).tag(Optional(apiCompatibilityMode.id))
                }
            }
            .pickerStyle(.menu)

            Button(role: .destructive) {
                // Force all views and API clients to update.
                rootViewModel.identitySelected(id: nil)
                rootViewModel.identitySelected(id: identityContext.identity.id)
            } label: {
                Label {
                    Text("preferences.api-compatibility-mode.apply")
                } icon: {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(apiCompatibilityModeChanged ? .red : .gray)
                }
            }
            .disabled(!apiCompatibilityModeChanged)

            Button(role: .destructive) {
                rootViewModel.clearNavigationCache()
            } label: {
                Label {
                    Text("preferences.cache.clear.navigation")
                } icon: {
                    Image(systemName: "trash")
                }
            }

            // App-wide HTML parser switch.
            Picker("preferences.html-parser.picker-title", selection: Binding<HTML.Parser>(
                get: { HTML.parser },
                set: {
                    HTML.parser = $0
                    UserDefaults(suiteName: AppMetadata.appGroup)!.set($0.rawValue, forKey: "HTML.parser")
                }
            )) {
                ForEach(HTML.Parser.allCases) { parser in
                    Text(parser.rawValue).tag(parser.id)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

extension APICompatibilityMode {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .fallbackOnErrors:
            return "preferences.api-compatibility-mode.fallback-on-errors"
        case .failOnErrors:
            return "preferences.api-compatibility-mode.fail-on-errors"
        }
    }
}

extension HTML.Parser {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .webkit:
            return "preferences.html-parser.webkit"
        case .siren:
            return "preferences.html-parser.siren"
        }
    }
}

#if DEBUG
import PreviewViewModels

struct AppPreferencesSection_Previews: PreviewProvider {
    @StateObject var viewModel: PreferencesViewModel = .init(identityContext: .preview)

    static var previews: some View {
        let data = Self()
        AppPreferencesSection(viewModel: data.viewModel, identityContext: data.viewModel.identityContext)
    }
}
#endif
