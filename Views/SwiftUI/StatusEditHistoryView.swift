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
                            CloseButton {
                                dismiss()
                            }
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
                            Text(attributedContent(version, language: viewModel.language))
                                .textSelection(.enabled)
                                .environment(\.openURL, OpenURLAction { url in
                                    dismiss()
                                    viewModel.openURL(url)
                                    return .handled
                                })
                        }
                        .scenePadding()
                    }
                } else {
                    Text("status.edit-history.versions.select")
                        .scenePadding()
                }
            }
        } else {
            NavigationView {
                List(viewModel.versions, selection: $selected) { version in
                    NavigationLink {
                        ScrollView {
                            VStack {
                                if let spoiler = version.spoiler {
                                    Text(verbatim: spoiler)
                                        .textSelection(.enabled)
                                    Divider()
                                }
                                Text(attributedContent(version, language: viewModel.language))
                                    .textSelection(.enabled)
                                    .environment(\.openURL, OpenURLAction { url in
                                        dismiss()
                                        viewModel.openURL(url)
                                        return .handled
                                    })
                            }
                            .scenePadding()
                        }
                    } label: {
                        // TODO: (Vyr) proper formatter
                        Text(version.date, style: .date)
                        + Text(verbatim: " ")
                        + Text(version.date, style: .time)
                    }
                }
                .navigationTitle("status.edit-history.versions")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CloseButton {
                            dismiss()
                        }
                    }
                }
            }
            .navigationViewStyle(.columns)
        }
    }

    private func attributedContent(
        _ version: StatusHistoryViewModel.Version,
        language: String?
    ) -> AttributedString {
        var formatted = version.content.formatSiren(.body)
        formatted.swiftUI.foregroundColor = .init(uiColor: .label)
        for (quoteLevel, range) in formatted.runs[\.quoteLevel].reversed() {
            guard let quoteLevel = quoteLevel, quoteLevel > 0 else { continue }
            formatted.characters.insert(contentsOf: String(repeating: "> ", count: quoteLevel), at: range.lowerBound)
        }
        if let language = language {
            formatted.languageIdentifier = language
        }
        return formatted
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

#if DEBUG
import PreviewViewModels

// TODO: (Vyr) why does this always crash unless the HTML part is commented out?
struct StatusEditHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        StatusEditHistoryView(.preview)
    }
}
#endif
