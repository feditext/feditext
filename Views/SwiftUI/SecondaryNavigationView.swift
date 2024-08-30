// Copyright © 2020 Metabolist. All rights reserved.

import MastodonAPI
import SwiftUI
import ViewModels

struct SecondaryNavigationView: View {
    @ObservedObject var viewModel: NavigationViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        Form {
            Section {
                if let id = viewModel.identityContext.identity.account?.id {
                    Button {
                        viewModel.navigateToProfile(id: id)
                    } label: {
                        Label {
                            Text("secondary-navigation.my-profile").foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "person.crop.square")
                        }
                    }
                    if viewModel.hasEditProfile {
                        Button {
                            viewModel.navigateToEditProfile()
                        } label: {
                            Label {
                                Text("secondary-navigation.edit-profile").foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "pencil")
                            }
                        }
                    }
                    if viewModel.hasAccountSettings {
                        Button {
                            viewModel.navigateToAccountSettings()
                        } label: {
                            Label {
                                Text("secondary-navigation.account-settings").foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "person.crop.square.filled.and.at.rectangle")
                            }
                        }
                    }
                }
                NavigationLink(
                    destination: IdentitiesView { .init(identityContext: viewModel.identityContext) }
                        .environmentObject(rootViewModel)) {
                    Label("secondary-navigation.accounts", systemImage: "rectangle.stack.person.crop")
                }
            }
            if viewModel.identityContext.identity.authenticated && !viewModel.identityContext.identity.pending {
                Section {
                    if ListsEndpoint.lists.canCallWith(viewModel.identityContext.apiCapabilities) {
                        NavigationLink(
                            destination: ListsView(viewModel: .init(identityContext: viewModel.identityContext))
                                .environmentObject(rootViewModel)
                        ) {
                            Label("secondary-navigation.lists", systemImage: "scroll")
                        }
                    }

                    if TagsEndpoint.followed.canCallWith(viewModel.identityContext.apiCapabilities) {
                        NavigationLink(
                            destination: FollowedTagsView(viewModel: .init(identityContext: viewModel.identityContext))
                                .environmentObject(rootViewModel)
                        ) {
                            Label("secondary-navigation.followed-tags", systemImage: "number")
                        }
                    }

                    Button {
                        viewModel.navigate(timeline: .favorites)
                    } label: {
                        Label {
                            Text(Timeline.favorites.title).foregroundColor(.primary)
                        } icon: {
                            Image(systemName: Timeline.favorites.systemImageName)
                        }
                    }

                    if StatusesEndpoint.bookmarks.canCallWith(viewModel.identityContext.apiCapabilities) {
                        Button {
                            viewModel.navigate(timeline: .bookmarks)
                        } label: {
                            Label {
                                Text(Timeline.bookmarks.title).foregroundColor(.primary)
                            } icon: {
                                Image(systemName: Timeline.bookmarks.systemImageName)
                            }
                        }
                    }

                    if let followRequestCount = viewModel.identityContext.identity.account?.followRequestCount,
                       followRequestCount > 0 {
                        Button {
                            viewModel.navigateToFollowerRequests()
                        } label: {
                            Label {
                                HStack {
                                    Text("follow-requests").foregroundColor(.primary)
                                    Spacer()
                                    Text(verbatim: String(followRequestCount))
                                }
                            } icon: {
                                Image(systemName: "person.badge.plus")
                            }
                        }
                    }
                }
            }
            Section {
                NavigationLink(
                    destination: PreferencesView(viewModel: .init(identityContext: viewModel.identityContext))
                        .environmentObject(rootViewModel)) {
                    Label("secondary-navigation.preferences", systemImage: "gear")
                }
                NavigationLink(
                    destination: AboutInstanceLoader(
                        exploreViewModel: viewModel.exploreViewModel(),
                        navigationViewModel: viewModel,
                        identityContext: viewModel.identityContext
                    )
                ) {
                    Label {
                        Text(verbatim: aboutInstanceLocalizedTitle)
                    } icon: {
                        Image(systemName: "server.rack")
                    }
                }
                NavigationLink(
                    destination: AboutView(viewModel: viewModel)
                        .environmentObject(rootViewModel)) {
                    Label("secondary-navigation.about", systemImage: "info.circle")
                }
            }
        }
    }

    /// Return a string based on the instance's URI, or a fallback if it's not available for some reason.
    private var aboutInstanceLocalizedTitle: String {
        if let domain = viewModel.identityContext.identity.instance?.domain {
            return String.localizedStringWithFormat(
                NSLocalizedString("secondary-navigation.about-instance-%@", comment: ""),
                domain
            )
        } else {
            return NSLocalizedString("secondary-navigation.about-this-instance", comment: "")
        }
    }

    // TODO: (Vyr) this doesn't really work as intended.
    //  Test it by breaking `/api/v1/instance`; the blank view shows and looks weird.
    /// Exists entirely to wait for the instance view model to load.
    private struct AboutInstanceLoader: View {
        @ObservedObject var exploreViewModel: ExploreViewModel
        @ObservedObject var navigationViewModel: NavigationViewModel
        @ObservedObject var identityContext: IdentityContext

        var body: some View {
            if let instanceViewModel = exploreViewModel.instanceViewModel {
                AboutInstanceView(
                    viewModel: instanceViewModel,
                    navigationViewModel: navigationViewModel,
                    apiCapabilitiesViewModel: .init(apiCapabilities: identityContext.apiCapabilities)
                )
            } else {
                EmptyView()
            }
        }
    }
}

#if DEBUG
import PreviewViewModels

struct SecondaryNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        SecondaryNavigationView(viewModel: NavigationViewModel(identityContext: .preview, environment: .preview))
            .environmentObject(RootViewModel.preview)
    }
}
#endif
