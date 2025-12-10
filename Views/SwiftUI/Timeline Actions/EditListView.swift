// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon
import SwiftUI
import ViewModels

/// Edit list settings.
public struct EditListView: View {
  @ObservedObject var viewModel: EditListViewModel

  @Environment(\.dismiss) private var dismiss

  public var body: some View {
    if #available(iOS 16.0, *) {
      NavigationStack {
        editor
      }
    } else {
      NavigationView {
        editor
      }
    }
  }

  private var editor: some View {
    Form {
      TextField("lists.edit-list.title", text: $viewModel.title)

      if viewModel.canUseRepliesPolicy {
        Picker("lists.edit-list.replies-policy", selection: $viewModel.repliesPolicy) {
          ForEach(Mastodon.List.RepliesPolicy.allCasesExceptUnknown) { policy in
            Text(policy.localizedStringKey).tag(policy)
          }
        }
      }

      if viewModel.canUseExclusive {
        Toggle("lists.edit-list.exclusive", isOn: $viewModel.exclusive)
      }
    }
    .navigationTitle(
      String.localizedStringWithFormat(
        NSLocalizedString("lists.edit-list.view-title-%@", comment: ""),
        viewModel.originalTitle
      )
    )
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        CloseButton {
          dismiss()
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("update.action") {
          viewModel.update()
          dismiss()
        }
        .disabled(viewModel.title.isEmpty)
      }
    }
  }
}
