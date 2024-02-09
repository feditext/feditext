// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import MastodonAPI
import ServiceLayer

public final class NavigationViewModel: ObservableObject {
    public let identityContext: IdentityContext
    public let navigations: AnyPublisher<Navigation, Never>

    @Published public private(set) var recentIdentities = [Identity]()
    @Published public private(set) var announcementCount: (total: Int, unread: Int) = (0, 0)
    @Published public var presentedComposeStatusViewModel: ComposeStatusViewModel?
    @Published public var presentingSecondaryNavigation = false
    @Published public var alertItem: AlertItem?

    private let navigationsSubject = PassthroughSubject<Navigation, Never>()
    private let environment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext, environment: AppEnvironment) {
        self.identityContext = identityContext
        self.environment = environment
        navigations = navigationsSubject.eraseToAnyPublisher()

        identityContext.$identity
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        identityContext.service.recentIdentitiesPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)

        identityContext.service.announcementCountPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$announcementCount)
    }
}

public extension NavigationViewModel {
    enum Tab: Int, CaseIterable {
        case timelines
        case explore
        case notifications
        case messages
    }

    var timelines: [Timeline] {
        if identityContext.identity.authenticated {
            return Timeline.authenticatedDefaults
        } else {
            return Timeline.unauthenticatedDefaults
        }
    }

    func refreshIdentity() {
        if identityContext.identity.pending {
            identityContext.service.verifyCredentials()
                .collect()
                .map { _ in () }
                .flatMap(identityContext.service.confirmIdentity)
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        } else if identityContext.identity.authenticated {
            identityContext.service.verifyCredentials()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
            identityContext.service.refreshLists()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
            identityContext.service.refreshFilters()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
            identityContext.service.refreshFollowedTags()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
            identityContext.service.refreshEmojis()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
            identityContext.service.refreshAnnouncements()
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)

            if identityContext.identity.preferences.useServerPostingReadingPreferences {
                identityContext.service.refreshServerPreferences()
                    .sink { _ in } receiveValue: { _ in }
                    .store(in: &cancellables)
            }
        }

        // TODO: (Vyr) perf: this currently also calls the instance API. Merge with refreshInstance below?
        identityContext.service.refreshAPICapabilities()
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)

        identityContext.service.refreshInstance()
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func navigateToProfile(id: Account.Id) {
        presentingSecondaryNavigation = false
        presentedComposeStatusViewModel = nil
        navigationsSubject.send(.profile(identityContext.service.navigationService.profileService(id: id)))
    }

    var hasEditProfile: Bool {
        identityContext.service.navigationService.editProfile() != nil
    }

    func navigateToEditProfile() {
        guard let navigation = identityContext.service.navigationService.editProfile() else { return }

        navigationsSubject.send(navigation)
    }

    var hasAccountSettings: Bool {
        identityContext.service.navigationService.accountSettings() != nil
    }

    func navigateToAccountSettings() {
        guard let navigation = identityContext.service.navigationService.accountSettings() else { return }

        navigationsSubject.send(navigation)
    }

    func navigate(timeline: Timeline) {
        presentingSecondaryNavigation = false
        presentedComposeStatusViewModel = nil
        navigationsSubject.send(
            .collection(identityContext.service.navigationService.timelineService(timeline: timeline)))
    }

    func navigateToFollowerRequests() {
        presentingSecondaryNavigation = false
        presentedComposeStatusViewModel = nil
        navigationsSubject.send(.collection(identityContext.service.service(
                                                accountList: .followRequests,
                                                titleComponents: ["follow-requests"])))
    }

    func navigateToMutedUsers() {
        presentingSecondaryNavigation = false
        presentedComposeStatusViewModel = nil
        navigationsSubject.send(.collection(identityContext.service.service(
                                                accountList: .mutes,
                                                titleComponents: ["preferences.muted-users"])))
    }

    func navigateToBlockedUsers() {
        presentingSecondaryNavigation = false
        presentedComposeStatusViewModel = nil
        navigationsSubject.send(.collection(identityContext.service.service(
                                                accountList: .blocks,
                                                titleComponents: ["preferences.blocked-users"])))
    }

    func navigateToURL(_ url: URL) {
        presentingSecondaryNavigation = false
        presentedComposeStatusViewModel = nil
        identityContext.service.navigationService.lookup(url: url, identityId: identityContext.identity.id)
            .sink { [weak self] in self?.navigationsSubject.send($0) }
            .store(in: &cancellables)
    }

    func navigate(pushNotification: PushNotification) {
        switch pushNotification.notificationType {
        case .followRequest:
            navigateToFollowerRequests()
        default:
            identityContext.service.notificationService(pushNotification: pushNotification)
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { [weak self] in
                    self?.presentingSecondaryNavigation = false
                    self?.presentedComposeStatusViewModel = nil
                    self?.navigationsSubject.send(.notification($0))
                }
                .store(in: &cancellables)
        }
    }

    func viewModel(timeline: Timeline) -> CollectionItemsViewModel {
        CollectionItemsViewModel(
            collectionService: identityContext.service.navigationService.timelineService(timeline: timeline),
            identityContext: identityContext)
    }

    func exploreViewModel() -> ExploreViewModel {
        let exploreViewModel = ExploreViewModel(
            service: identityContext.service.exploreService(),
            identityContext: identityContext)

        exploreViewModel.refresh()

        return exploreViewModel
    }

    func notificationsViewModel(excludeTypes: Set<MastodonNotification.NotificationType>) -> CollectionItemsViewModel {
        let viewModel = CollectionItemsViewModel(
            collectionService: identityContext.service.notificationsService(excludeTypes: excludeTypes),
            identityContext: identityContext)

        if excludeTypes.isEmpty {
            viewModel.request(maxId: nil, minId: nil)
        }

        return viewModel
    }

    var canListConversations: Bool {
        ConversationsEndpoint.conversations.canCallWith(identityContext.apiCapabilities)
    }

    func conversationsViewModel() -> CollectionViewModel {
        let conversationsViewModel = CollectionItemsViewModel(
            collectionService: identityContext.service.conversationsService(),
            identityContext: identityContext)

        conversationsViewModel.request(maxId: nil, minId: nil)

        return conversationsViewModel
    }

    func announcementsViewModel() -> CollectionViewModel {
        CollectionItemsViewModel(
            collectionService: identityContext.service.announcementsService(),
            identityContext: identityContext)
    }
}
