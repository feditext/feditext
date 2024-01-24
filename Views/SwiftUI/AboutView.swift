// Copyright © 2021 Metabolist. All rights reserved.

import AppUrls
import SwiftUI
import ViewModels

struct AboutView: View {
    @StateObject var viewModel: NavigationViewModel

    var body: some View {
        Form {
            Section {
                VStack(spacing: .defaultSpacing) {
                    Text(verbatim: Self.appName)
                        .font(.largeTitle)
                    Text(verbatim: "\(Self.version) (\(Self.build))")
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            Section {
                Button {
                    viewModel.navigateToURL(Self.officialAccountURL)
                } label: {
                    Label {
                        Text("about.official-account").foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "checkmark.seal")
                    }
                }
                Link(destination: Self.sourceCodeAndIssueTrackerURL) {
                    Label {
                        Text("about.source-code-and-issue-tracker").foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "wrench.and.screwdriver")
                    }
                }
            }
            Section("about.maintained-by") {
                ForEach(Self.maintainers) { maintainer in
                    Button {
                        viewModel.navigateToURL(maintainer.url)
                    } label: {
                        Label {
                            Text(verbatim: maintainer.name).foregroundColor(.primary)
                        } icon: {
                            Text(verbatim: maintainer.emoji).foregroundColor(.primary)
                        }
                    }
                }
            }
            Section("about.made-by-metabolist") {
                Text("about.made-by-metabolist.blurb")
                    .font(.subheadline)
                Link(destination: Self.metabolistWebsiteURL) {
                    Label {
                        Text("about.website").foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "star")
                    }
                }
            }
            Section {
                NavigationLink(
                    destination: AcknowledgmentsView()) {
                    Label("about.acknowledgments", systemImage: "curlybraces")
                }
            }
        }
        .navigationTitle("about")
    }
}

private extension AboutView {
    static let officialAccountURL = URL(string: "https://mastodon.social/@Feditext")!
    static let sourceCodeAndIssueTrackerURL = AppUrl.website

    struct Maintainer: Identifiable {
        let name: String
        let emoji: String
        let url: URL

        var id: String { name }
    }

    static let maintainers: [Maintainer] = [
        Maintainer(name: "Brian Dube", emoji: "🐐", url: URL(string: "https://gotgoat.com/@bdube")!),
        Maintainer(name: "Vyr Cossont", emoji: "😈", url: URL(string: "https://demon.social/@vyr")!)
    ]

    static let metabolistWebsiteURL = URL(string: "https://metabolist.org")!

    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? ""
    }

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
    }
}

#if DEBUG
import PreviewViewModels

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(viewModel: NavigationViewModel(identityContext: .preview, environment: .preview))
    }
}
#endif
