// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer
import SwiftUI
import ViewModels

/// Display a list of previous versions of a post.
/// Note that this re-implements `StatusBodyView` in SwiftUI,
/// and does not yet have all the features of the original.
public struct StatusEditHistoryView: View {
    private let viewModel: StatusHistoryViewModel
    @State private var selected: StatusHistoryViewModel.Version.ID?

    @Environment(\.dismiss) private var dismiss

    public init(_ viewModel: StatusHistoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if viewModel.versions.isEmpty {
            switch viewModel.statusWord {
            case .post:
                Text("status.edit-history.not-available.post")
                    .scenePadding()
            case .toot:
                Text("status.edit-history.not-available.toot")
                    .scenePadding()
            }
        } else if #available(iOS 16.0, *) {
            NavigationSplitView {
                NavigationStack {
                    List(viewModel.versions, selection: $selected) { version in
                        // TODO: (Vyr) proper formatter
                        Text(version.date, style: .date)
                            + Text(verbatim: " ")
                            + Text(version.date, style: .time)
                    }
                    .navigationTitle("status.edit-history.versions")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Label("dismiss", systemImage: "xmark.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.plain)
                        }
                    }
                }
            } detail: {
                if let id = selected {
                    let version = viewModel.versions[id]
                    ScrollView {
                        VStack {
                            if let spoiler = version.spoiler {
                                Text(verbatim: spoiler)
                                    .textSelection(.enabled)
                                Divider()
                            }
                            Text(attributedContent(version))
                                .textSelection(.enabled)
                                .environment(\.openURL, OpenURLAction { url in
                                    dismiss()
                                    viewModel.openURL(url)
                                    return .handled
                                })
                        }
                    }
                } else {
                    Text("status.edit-history.versions.select")
                        .scenePadding()
                }
            }
        } else {
            // TODO: (Vyr) rewrite as NavigationView
            Text("""
                 Vyr says: You currently need iOS 16 or higher to see a post's edit history.
                 Support for older versions is coming!
                 """)
                .scenePadding()
        }
    }

    private func attributedContent(_ version: StatusHistoryViewModel.Version) -> AttributedString {
        let mutable = NSMutableAttributedString(attributedString: version.content)
        mutable.adaptHtmlFonts(style: .body)
        // TODO: (Vyr) disabled for now: we need a way to re-display the content after the emojis load
        // mutable.insert(emojis: version.emojis, identityContext: viewModel.identityContext)
        return AttributedString(mutable)
    }
}

struct StatusBodyViewRepresentable: UIViewRepresentable {
    typealias Context = UIViewRepresentableContext<Self>

    let viewModel: StatusViewModel

    func makeUIView(context: Context) -> StatusBodyView {
        let statusBodyView = StatusBodyView(frame: .null)
        statusBodyView.viewModel = viewModel
        return statusBodyView
    }

    func updateUIView(_ statusBodyView: StatusBodyView, context: Context) {
        statusBodyView.viewModel = viewModel
    }
}
