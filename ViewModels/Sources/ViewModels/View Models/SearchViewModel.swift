// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import ServiceLayer

/// View model for Explore tab searches. Also used for autocompleting tags.
/// - SeeAlso: ``AccountSearchViewModel``
public final class SearchViewModel: CollectionItemsViewModel {
  @Published public var query = ""
  @Published public var scope = SearchScope.all

  private let purpose: Purpose
  private let searchService: SearchService
  private var cancellables = Set<AnyCancellable>()

  /// Why are we searching?
  public enum Purpose {
    /// Explore tab searches might trigger expensive actions like full-text status search.
    case exploreTab
    /// Autocomplete in the composition view expects to get accounts or tags quickly by name while the user is typing.
    case compositionAutocomplete

    var debounceInterval: TimeInterval {
      switch self {
      case .exploreTab: 0.8
      case .compositionAutocomplete: 0.1
      }
    }
  }

  public init(identityContext: IdentityContext, _ purpose: Purpose) {
    self.purpose = purpose
    self.searchService = identityContext.service.searchService()

    super.init(collectionService: searchService, identityContext: identityContext)

    $query.dropFirst()
      .debounce(for: .seconds(purpose.debounceInterval), scheduler: DispatchQueue.global())
      .removeDuplicates()
      .combineLatest($scope.removeDuplicates())
      .sink { [weak self] query, scope in
        guard let self = self else { return }
        self.cancelRequests()
        self.searchService.query = query
        self.searchService.type = scope.type
        self.searchService.limit = scope.limit
        self.request(maxId: nil, minId: nil)
      }
      .store(in: &cancellables)
  }

  public override func requestNextPage(fromIndexPath indexPath: IndexPath) {
    guard scope != .all else { return }

    request(maxId: nextPageMaxId, minId: nil)
  }
}

extension SearchScope {
  fileprivate var type: Search.SearchType? {
    switch self {
    case .all:
      return nil
    case .accounts:
      return .accounts
    case .statuses:
      return .statuses
    case .tags:
      return .hashtags
    }
  }

  fileprivate var limit: Int? {
    switch self {
    case .all:
      return 5
    default:
      return nil
    }
  }
}
