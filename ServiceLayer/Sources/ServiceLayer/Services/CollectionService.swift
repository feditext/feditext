// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Mastodon

public protocol CollectionService {
    var sections: AnyPublisher<[[CollectionItem]], Error> { get }
    var nextPageMaxId: AnyPublisher<String, Never> { get }
    var title: AnyPublisher<String, Never> { get }
    var navigationService: NavigationService { get }
    func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error>
    func toggleShowMore(id: Status.Id) -> AnyPublisher<Never, Error>
}

extension CollectionService {
    public var nextPageMaxId: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    public var title: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }
}
