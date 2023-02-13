// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class FollowedTagsViewModel: ObservableObject {
    @Published public private(set) var tags = [FollowedTag]()
    @Published public private(set) var creating = false
    @Published public var alertItem: AlertItem?
    public let identityContext: IdentityContext

    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext

        identityContext.service.followedTagsPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .map { $0.sorted() }
            .assign(to: &$tags)
    }
}

public extension FollowedTagsViewModel {
    func refresh() {
        identityContext.service.refreshFilters()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func create(name: Tag.Name) {
        identityContext.service.followTag(name: name)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.creating = true },
                receiveCompletion: { [weak self] _ in self?.creating = false })
            .sink { _ in }
            .store(in: &cancellables)
    }

    func delete(name: Tag.Name) {
        identityContext.service.unfollowTag(name: name)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
