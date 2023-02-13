// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon
import SwiftUI
import ViewModels

/// Display instance description and rules.
struct AboutInstanceView: View {
    let viewModel: InstanceViewModel
    let navigationViewModel: NavigationViewModel

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
                Text(verbatim: viewModel.instance.version)
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

    // TODO: (Vyr) extract this code from `StatusHistoryEditView` for reuse across SwiftUI
    private var attributedDescription: AttributedString? {
        guard !viewModel.instance.description.raw.isEmpty else {
            return nil
        }
        let mutable = NSMutableAttributedString(attributedString: viewModel.instance.description.attributed)
        mutable.adaptHtmlAttributes(style: .body)
        let entireString = NSRange(location: 0, length: mutable.length)
        mutable.addAttribute(
            .foregroundColor,
            value: UIColor.label,
            range: entireString
        )
        mutable.enumerateAttribute(HTML.Key.quoteLevel, in: entireString) { val, range, _ in
            guard let quoteLevel = val as? Int,
                  quoteLevel > 0 else {
                return
            }
            mutable.replaceCharacters(
                in: NSRange(location: range.location, length: 0),
                with: String(repeating: "> ", count: quoteLevel)
            )
        }
        return AttributedString(mutable)
    }
}

#if DEBUG
import PreviewViewModels

struct AboutInstanceView_Previews: PreviewProvider {
    static var previews: some View {
        AboutInstanceView(
            viewModel: .preview,
            navigationViewModel: .preview
        )
    }
}
#endif
