// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon
import SwiftUI
import ViewModels

// TODO: (Vyr) display the instance banner, admin contact info, etc.
/// Display instance description and rules in the secondary navigation area.
/// Not to be confused with ``InstanceView``.
struct AboutInstanceView: View {
    let viewModel: InstanceViewModel
    let navigationViewModel: NavigationViewModel
    let apiCapabilitiesViewModel: APICapabilitiesViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                if let shortDescription = viewModel.instance.shortDescription {
                    Text(verbatim: shortDescription)
                }
                if let attributedDescription = attributedDescription {
                    Text(attributedDescription)
                        .environment(\.openURL, OpenURLAction { url in
                            dismiss()
                            navigationViewModel.navigateToURL(url)
                            return .handled
                        })
                }
            } header: {
                Text(
                    verbatim: String.localizedStringWithFormat(
                        NSLocalizedString("instance.about-instance-title-%@", comment: ""),
                        viewModel.instance.title
                    )
                )
            }
            Section("instance.version") {
                if let localizedName = apiCapabilitiesViewModel.localizedName {
                    if let homepage = apiCapabilitiesViewModel.homepage {
                        Button {
                            navigationViewModel.navigateToURL(homepage)
                        } label: {
                            Label {
                                Text(localizedName).foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "info.circle")
                            }
                        }
                    } else {
                        Text(localizedName)
                    }
                }
                if let version = apiCapabilitiesViewModel.version {
                    Text(verbatim: version)
                }
            }
            Section("instance.registration") {
                Text(
                    viewModel.instance.registrations
                    ? "instance.registration.registration-open"
                    : "instance.registration.registration-closed"
                )
                Text(
                    viewModel.instance.approvalRequired
                    ? "instance.registration.approval-required"
                    : "instance.registration.approval-not-required"
                )
                Text(
                    viewModel.instance.invitesEnabled
                    ? "instance.registration.invites-enabled"
                    : "instance.registration.invites-disabled"
                )
            }
            Section("instance.rules") {
                ForEach(viewModel.instance.rules) { rule in
                    Text(verbatim: rule.text)
                }
            }
        }
    }

    // TODO: (Vyr) extract this code from `StatusEditHistoryView` for reuse across SwiftUI
    private var attributedDescription: AttributedString? {
        guard !viewModel.instance.description.raw.isEmpty else {
            return nil
        }
        var formatted = viewModel.instance.description.attrStr.formatSiren(.body)
        formatted.swiftUI.foregroundColor = .init(uiColor: .label)
        for (quoteLevel, range) in formatted.runs[\.quoteLevel].reversed() {
            guard let quoteLevel = quoteLevel, quoteLevel > 0 else { continue }
            formatted.characters.insert(contentsOf: String(repeating: "> ", count: quoteLevel), at: range.lowerBound)
        }
        return formatted
    }
}

#if DEBUG
import PreviewViewModels

struct AboutInstanceView_Previews: PreviewProvider {
    static var previews: some View {
        AboutInstanceView(
            viewModel: .preview,
            navigationViewModel: .preview,
            apiCapabilitiesViewModel: .preview
        )
    }
}
#endif
