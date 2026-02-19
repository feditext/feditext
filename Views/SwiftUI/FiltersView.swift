// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SwiftUI
import ViewModels

struct FiltersView: View {
  @StateObject var viewModel: FiltersViewModel
  @ObservedObject var preferencesViewModel: PreferencesViewModel

  var body: some View {
    Form {
      Section {
        NavigationLink(
          destination: EditFilterView(
            viewModel: .init(filter: .new, identityContext: viewModel.identityContext)
          )
        ) {
          Label("add", systemImage: "plus.circle")
        }
      }
      section(title: "filters.active", filters: viewModel.activeFilters)
      section(title: "filters.expired", filters: viewModel.expiredFilters)

      // FIXME: move to FilterV2sViewModel
      if preferencesViewModel.supportsV2Filters {
        Section {
          TextField(
            "preferences.filters.quick-status-filter.name",
            text: Binding(
              get: { preferencesViewModel.preferences.quickStatusFilter ?? "" },
              set: { preferencesViewModel.preferences.quickStatusFilter = $0 == "" ? nil : $0 }
            )
          )
        }
      }
    }
    .navigationTitle("preferences.filters")
    .toolbar {
      ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
        EditButton()
      }
    }
    .alertItem($viewModel.alertItem)
    .onAppear(perform: viewModel.refreshFilters)
  }
}

extension FiltersView {
  @ViewBuilder
  fileprivate func section(title: LocalizedStringKey, filters: [Filter]) -> some View {
    if !filters.isEmpty {
      Section(header: Text(title)) {
        ForEach(filters) { filter in
          NavigationLink(
            destination: EditFilterView(
              viewModel: .init(filter: filter, identityContext: viewModel.identityContext)
            )
          ) {
            HStack {
              Text(filter.phrase)
              Spacer()
              Text(ListFormatter.localizedString(byJoining: filter.context.map(\.localized)))
                .foregroundColor(.secondary)
            }
          }
        }
        .onDelete {
          guard let index = $0.first else { return }

          viewModel.delete(filter: filters[index])
        }
      }
    }
  }
}

#if DEBUG
  import PreviewViewModels

  struct FiltersView_Previews: PreviewProvider {
    static var previews: some View {
      FiltersView(
        viewModel: .init(identityContext: .preview),
        preferencesViewModel: .init(identityContext: .preview)
      )
    }
  }
#endif
