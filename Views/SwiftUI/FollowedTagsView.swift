// Copyright © 2023 Vyr Cossont. All rights reserved.

import Mastodon
import SwiftUI
import ViewModels

struct FollowedTagsView: View {
    @StateObject var viewModel: FollowedTagsViewModel
    @EnvironmentObject var rootViewModel: RootViewModel
    @State private var newName: Tag.Name = ""

    var body: some View {
        Form {
            Section {
                TextField("followed-tags.new-tag-title", text: $newName)
                    .disabled(viewModel.creating)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if viewModel.creating {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button {
                        viewModel.create(name: newName.trimmingCharacters(in: .whitespacesAndNewlines))
                    } label: {
                        Label("add", systemImage: "plus.circle")
                    }
                    .disabled(newName.isEmpty || newName.hasPrefix("#"))
                }
            }
            Section {
                ForEach(viewModel.tags) { tag in
                    Button {
                        rootViewModel.navigationViewModel?.navigate(timeline: .tag(tag.name))
                    } label: {
                        Text(tag.name)
                            .foregroundColor(.primary)
                    }
                }
                .onDelete {
                    guard let index = $0.first else { return }

                    viewModel.delete(name: viewModel.tags[index].name)
                }
            }
        }
        .navigationTitle(Text("secondary-navigation.followed-tags"))
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                EditButton()
            }
        }
        .alertItem($viewModel.alertItem)
        .onAppear(perform: viewModel.refresh)
        .onReceive(viewModel.$creating) {
            if !$0 {
                newName = ""
            }
        }
    }
}


#if DEBUG
import PreviewViewModels

struct FollowedTagsView_Previews: PreviewProvider {
    static var previews: some View {
        FollowedTagsView(viewModel: .init(identityContext: .preview))
            .environmentObject(NavigationViewModel(identityContext: .preview, environment: .preview))
    }
}
#endif
