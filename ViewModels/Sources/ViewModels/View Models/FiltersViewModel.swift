// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

/// View model for the list of the user's filters.
public final class FiltersViewModel: ObservableObject {
  @Published public var activeFilters = [Filter]()
  @Published public var expiredFilters = [Filter]()
  /// If v2 filters are available (`supportsV2Filters` is true), v1 filters will be empty.
  @Published public var allFilterV2s = [FilterV2]()
  @Published public var alertItem: AlertItem?
  public let identityContext: IdentityContext

  private var cancellables = Set<AnyCancellable>()

  public init(identityContext: IdentityContext) {
    self.identityContext = identityContext

    identityContext.service.activeFiltersPublisher()
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .assign(to: &$activeFilters)

    identityContext.service.expiredFiltersPublisher()
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .assign(to: &$expiredFilters)

    identityContext.service.allFilterV2sPublisher()
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .assign(to: &$allFilterV2s)
  }

  public var supportsV2Filters: Bool {
    identityContext.apiCapabilities.supportsV2Filters
  }

  public func refreshFilters() {
    identityContext.service.refreshFilters()
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .sink { _ in }
      .store(in: &cancellables)
  }

  public func delete(filter: Filter) {
    identityContext.service.deleteFilter(id: filter.id)
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .sink { _ in }
      .store(in: &cancellables)
  }
}
