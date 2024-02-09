// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class SearchViewModel: CollectionItemsViewModel {
    @Published public var query = ""
    @Published public var scope = SearchScope.all

    private let searchService: SearchService
    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.searchService = identityContext.service.searchService()

        super.init(collectionService: searchService, identityContext: identityContext)

        $query.dropFirst()
            .debounce(for: .seconds(Self.debounceInterval), scheduler: DispatchQueue.global())
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

private extension SearchViewModel {
    static let debounceInterval: TimeInterval = 0.8
}

private extension SearchScope {
    var type: Search.SearchType? {
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

    var limit: Int? {
        switch self {
        case .all:
            return 5
        default:
            return nil
        }
    }
}
