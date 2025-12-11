// Copyright © 2025 Vyr Cossont. All rights reserved.

import Combine
import DB
import Foundation
import ServiceLayer

/// View model for account name searches.
/// - SeeAlso: largely derived from ``SearchViewModel``.
public final class AccountSearchViewModel: CollectionItemsViewModel {
  @Published public var query = ""

  private let accountSearchService: AccountSearchService
  private var cancellables = Set<AnyCancellable>()

  public init(identityContext: IdentityContext) {
    self.accountSearchService = identityContext.service.accountSearchService()

    super.init(collectionService: accountSearchService, identityContext: identityContext)

    $query.dropFirst()
      .debounce(
        for: .seconds(SearchViewModel.Purpose.compositionAutocomplete.debounceInterval),
        scheduler: DispatchQueue.global()
      )
      .removeDuplicates()
      .sink { [weak self] query in
        guard let self = self else { return }
        self.cancelRequests()
        self.accountSearchService.query = query
        self.request(maxId: nil, minId: nil)
      }
      .store(in: &cancellables)
  }

  public override func requestNextPage(fromIndexPath indexPath: IndexPath) {
    request(maxId: nextPageMaxId, minId: nil)
  }
}
