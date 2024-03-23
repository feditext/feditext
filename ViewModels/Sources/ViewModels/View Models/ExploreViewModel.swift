// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class ExploreViewModel: ObservableObject {
    public let searchViewModel: SearchViewModel
    public let events: AnyPublisher<Event, Never>
    @Published public var instanceViewModel: InstanceViewModel?
    @Published public var announcementCount: (total: Int, unread: Int) = (0, 0)
    @Published public var tags = [Tag]()
    @Published public var links = [Card]()
    @Published public var statuses = [Status]()
    @Published public var recommendedStatuses = [Status]()
    @Published public private(set) var loading = false
    @Published public var alertItem: AlertItem?
    public let identityContext: IdentityContext

    private let exploreService: ExploreService
    private let eventsSubject = PassthroughSubject<Event, Never>()
    private let statusEventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(service: ExploreService, identityContext: IdentityContext) {
        exploreService = service
        self.identityContext = identityContext
        searchViewModel = SearchViewModel(identityContext: identityContext)
        events = eventsSubject.eraseToAnyPublisher()

        identityContext.service
            .instanceServicePublisher()
            .map { InstanceViewModel(instanceService: $0) }
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$instanceViewModel)

        identityContext.service.announcementCountPublisher()
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$announcementCount)

        // Forward collection navigation events to our events subject.
        statusEventsSubject
            .receive(on: DispatchQueue.main)
            .flatMap { $0.assignErrorsToAlertItem(to: \.alertItem, on: self) }
            .compactMap {
                switch $0 {
                case let CollectionItemEvent.navigation(nav):
                    return Event.navigation(nav)
                default:
                    // TODO: (Vyr) Explore tab: there are a ton of events we need to handle that can actually happen
                    //  For example, sharing a status, opening the emoji picker to react to a status…
                    assertionFailure("Untranslatable CollectionItemEvent: \($0)")
                    return nil
                }
            }
            .sink(receiveValue: { [weak self] in self?.eventsSubject.send($0) })
            .store(in: &cancellables)
    }
}

public extension ExploreViewModel {
    enum Event {
        case navigation(Navigation)
    }

    enum Section: Hashable {
        case tags
        case links
        case statuses
        case recommendedStatuses
        case instance
    }

    enum Item: Hashable {
        case tag(Tag)
        case link(Card)
        case status(Status)
        case instance
        case announcements(total: Int, unread: Int)
        case profileDirectory
        case suggestedAccounts
    }

    func refresh() {
        let refreshInstance = identityContext.service.refreshInstance()

        let refreshAnnouncements = identityContext.service.refreshAnnouncements()

        let refreshTags = exploreService.fetchTrendingTags()
            .handleEvents(receiveOutput: { [weak self] tags in
                DispatchQueue.main.async {
                    self?.tags = tags
                }
            })
            .ignoreOutput()

        let refreshLinks = exploreService.fetchTrendingLinks()
            .handleEvents(receiveOutput: { [weak self] links in
                DispatchQueue.main.async {
                    self?.links = links
                }
            })
            .ignoreOutput()

        let refreshStatuses = exploreService.fetchTrendingStatuses()
            .handleEvents(receiveOutput: { [weak self] statuses in
                DispatchQueue.main.async {
                    self?.statuses = statuses
                }
            })
            .ignoreOutput()

        let refreshRecommendedStatuses = exploreService.fetchRecommendedStatuses()
            .handleEvents(receiveOutput: { [weak self] statuses in
                DispatchQueue.main.async {
                    self?.recommendedStatuses = statuses
                }
            })
            .ignoreOutput()

        refreshInstance
            .merge(
                with: refreshAnnouncements,
                refreshTags,
                refreshLinks,
                refreshStatuses,
                refreshRecommendedStatuses
            )
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.loading = true },
                          receiveCompletion: { [weak self] _ in self?.loading = false })
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func viewModel(tag: Tag) -> TagViewModel {
        return .init(tag: tag, identityContext: identityContext)
    }

    func viewModel(card: Card) -> CardViewModel {
        .init(card: card)
    }

    func viewModel(status: Status) -> StatusViewModel {
        .init(
            statusService: exploreService.navigationService.statusService(status: status),
            identityContext: identityContext,
            eventsSubject: statusEventsSubject
        )
    }

    func select(item: ExploreViewModel.Item) {
        switch item {
        case let .tag(tag):
            eventsSubject.send(
                .navigation(
                    .collection(
                        exploreService.navigationService.timelineService(
                            timeline: .tag(tag.name)
                        )
                    )
                )
            )

        case let .link(card):
            guard let url = card.url.url else {
                assertionFailure("Link card doesn't have a valid URL")
                return
            }

            eventsSubject.send(.navigation(.url(url)))

        case let .status(status):
            eventsSubject.send(
                .navigation(
                    .collection(
                        exploreService.navigationService.contextService(
                            id: status.id
                        )
                    )
                )
            )

        case .instance:
            break

        case .announcements:
            eventsSubject.send(
                .navigation(
                    .collection(
                        identityContext.service.announcementsService()
                    )
                )
            )

        case .profileDirectory:
            eventsSubject.send(
                .navigation(
                    .collection(
                        identityContext.service.service(
                            accountList: .directory(local: true),
                            titleComponents: ["explore.profile-directory"]
                        )
                    )
                )
            )

        case .suggestedAccounts:
            eventsSubject.send(
                .navigation(
                    .collection(
                        identityContext.service.suggestedAccountListService(
                            titleComponents: ["explore.suggested-accounts"]
                        )
                    )
                )
            )
        }
    }
}
