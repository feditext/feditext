// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SwiftUI
import ViewModels

/// App-wide preferences.
struct AppPreferencesSection: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @ObservedObject var identityContext: IdentityContext

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
                NavigationLink("preferences.notifications",
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
    }
}

struct AppPreferencesSection_Previews: PreviewProvider {
    @StateObject var viewModel: PreferencesViewModel = .init(identityContext: .preview)

    static var previews: some View {
        let data = Self()
        AppPreferencesSection(viewModel: data.viewModel, identityContext: data.viewModel.identityContext)
    }
}
