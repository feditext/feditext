// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SwiftUI
import ViewModels

/// Show all of the user's existing lists and allow creating new ones.
struct ListsView: View {
  @StateObject var viewModel: ListsViewModel
  @EnvironmentObject var rootViewModel: RootViewModel
  @State private var newListTitle = ""
  @State private var newListRepliesPolicy: Mastodon.List.RepliesPolicy = .list
  @State private var newListExclusive: Bool = false

  var body: some View {
    Form {
      // New list.
      Section {
        TextField("lists.new-list-title", text: $newListTitle)
          .disabled(viewModel.creatingList)

        if viewModel.canUseRepliesPolicy {
          Picker("lists.edit-list.replies-policy", selection: $newListRepliesPolicy) {
            ForEach(Mastodon.List.RepliesPolicy.allCasesExceptUnknown) { policy in
              Text(policy.localizedStringKey).tag(policy)
            }
          }
          .disabled(viewModel.creatingList)
        }

        if viewModel.canUseExclusive {
          Toggle("lists.edit-list.exclusive", isOn: $newListExclusive)
            .disabled(viewModel.creatingList)
        }

        if viewModel.creatingList {
          ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
          Button {
            viewModel.createList(
              title: newListTitle,
              repliesPolicy: newListRepliesPolicy,
              exclusive: newListExclusive
            )
          } label: {
            Label("add", systemImage: "plus.circle.fill")
          }
          .disabled(newListTitle.isEmpty)
        }
      }

      // Existing lists.
      Section {
        ForEach(viewModel.lists) { list in
          Button {
            rootViewModel.navigationViewModel?.navigate(timeline: .list(list))
          } label: {
            Text(list.title)
              .foregroundColor(.primary)
          }
        }
        .onDelete {
          guard let index = $0.first else { return }

          viewModel.delete(list: viewModel.lists[index])
        }
      }
    }
    .navigationTitle(Text("secondary-navigation.lists"))
    .toolbar {
      ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
        EditButton()
      }
    }
    .alertItem($viewModel.alertItem)
    .onAppear(perform: viewModel.refreshLists)
    .onReceive(viewModel.$creatingList) {
      if !$0 {
        newListTitle = ""
        newListRepliesPolicy = .list
        newListExclusive = false
      }
    }
  }
}

#if DEBUG
  import PreviewViewModels

  struct ListsView_Previews: PreviewProvider {
    static var previews: some View {
      ListsView(viewModel: .init(identityContext: .preview))
        .environmentObject(NavigationViewModel(identityContext: .preview, environment: .preview))
    }
  }
#endif
