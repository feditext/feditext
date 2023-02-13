// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Mastodon
import ServiceLayer

/// Things we can do to a tag: get the current follow state, and follow or unfollow it.
public final class TagTimelineActionViewModel {
    private let name: Tag.Name
    private let identityContext: IdentityContext
    private var cancellables = Set<AnyCancellable>()
    private let tagSubject: CurrentValueSubject<Tag?, Never> = .init(nil)

    public var tag: AnyPublisher<Tag?, Never> {
        tagSubject.eraseToAnyPublisher()
    }

    public init(name: Tag.Name, identityContext: IdentityContext) {
        self.name = name
        self.identityContext = identityContext

        getTag()
    }

    private func getTag() {
        self.identityContext.service.getTag(name: name)
            .sink { _ in
                // Ignore completion
            } receiveValue: { [weak self] tag in
                self?.tagSubject.send(tag)
            }
            .store(in: &cancellables)
    }

    public func follow() {
        self.identityContext.service.followTag(name: name)
            .sink { _ in
                // Ignore completion
            } receiveValue: { [weak self] tag in
                self?.tagSubject.send(tag)
            }
            .store(in: &cancellables)
    }

    public func unfollow() {
        self.identityContext.service.unfollowTag(name: name)
            .sink { _ in
                // Ignore completion
            } receiveValue: { [weak self] tag in
                self?.tagSubject.send(tag)
            }
            .store(in: &cancellables)
    }
}
