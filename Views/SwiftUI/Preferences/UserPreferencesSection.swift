// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SwiftUI
import ViewModels

/// Preferences having to do with a given Mastodon user,
/// most of which are server-side, some of which can be overridden locally.
struct UserPreferencesSection: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @EnvironmentObject var rootViewModel: RootViewModel

    var body: some View {
        Section(header: Text(viewModel.identityContext.identity.handle)) {
            if viewModel.identityContext.identity.authenticated
                && !viewModel.identityContext.identity.pending {
                NavigationLink("preferences.filters",
                               destination: FiltersView(
                                viewModel: .init(identityContext: viewModel.identityContext)))
                if viewModel.shouldShowNotificationTypePreferences {
                    NavigationLink("preferences.notification-types",
                                   destination: NotificationTypesPreferencesView(
                                    viewModel: .init(identityContext: viewModel.identityContext)))
                }
                Button("preferences.muted-users") {
                    rootViewModel.navigationViewModel?.navigateToMutedUsers()
                }
                .foregroundColor(.primary)
                Button("preferences.blocked-users") {
                    rootViewModel.navigationViewModel?.navigateToBlockedUsers()
                }
                .foregroundColor(.primary)
                NavigationLink("preferences.blocked-domains",
                               destination: DomainBlocksView(viewModel: viewModel.domainBlocksViewModel()))
                Toggle("preferences.use-preferences-from-server",
                       isOn: $viewModel.preferences.useServerPostingReadingPreferences)
                Group {
                    Picker("preferences.posting-default-visibility",
                           selection: $viewModel.preferences.postingDefaultVisibility) {
                        Text("status.visibility.public").tag(Status.Visibility.public)
                        Text("status.visibility.unlisted").tag(Status.Visibility.unlisted)
                        Text("status.visibility.private").tag(Status.Visibility.private)
                    }
                    Toggle("preferences.posting-default-sensitive",
                           isOn: $viewModel.preferences.postingDefaultSensitive)
                    NavigationLink("preferences.posting-default-language") {
                        PostingDefaultLanguageView(
                            postingDefaultLanguage: $viewModel.preferences.postingDefaultLanguage
                        )
                    }
                }
                .disabled(viewModel.preferences.useServerPostingReadingPreferences)
            }
            Group {
                Picker("preferences.reading-expand-media",
                       selection: $viewModel.preferences.readingExpandMedia) {
                    Text("preferences.expand-media.default").tag(Preferences.ExpandMedia.default)
                    Text("preferences.expand-media.show-all").tag(Preferences.ExpandMedia.showAll)
                    Text("preferences.expand-media.hide-all").tag(Preferences.ExpandMedia.hideAll)
                }
                Toggle("preferences.reading-expand-spoilers",
                       isOn: $viewModel.preferences.readingExpandSpoilers)
            }
            .disabled(viewModel.preferences.useServerPostingReadingPreferences
                        && viewModel.identityContext.identity.authenticated)
        }
    }
}

struct UserPreferencesSection_Previews: PreviewProvider {
    struct Container: View {
        @StateObject var viewModel: PreferencesViewModel = .init(identityContext: .preview)

        var body: some View {
            UserPreferencesSection(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Self.Container()
    }
}
