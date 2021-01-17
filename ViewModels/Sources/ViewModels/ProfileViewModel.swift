// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

final public class ProfileViewModel {
    @Published public private(set) var accountViewModel: AccountViewModel?
    @Published public var collection = ProfileCollection.statuses
    @Published public var alertItem: AlertItem?
    public let imagePresentations: AnyPublisher<URL, Never>

    private let profileService: ProfileService
    private let collectionViewModel: CurrentValueSubject<CollectionItemsViewModel, Never>
    private let imagePresentationsSubject = PassthroughSubject<URL, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(profileService: ProfileService, identification: Identification) {
        self.profileService = profileService
        imagePresentations = imagePresentationsSubject.eraseToAnyPublisher()

        collectionViewModel = CurrentValueSubject(
            CollectionItemsViewModel(
                collectionService: profileService.timelineService(profileCollection: .statuses),
                identification: identification))

        profileService.accountServicePublisher
            .map { AccountViewModel(accountService: $0, identification: identification) }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$accountViewModel)

        $collection.dropFirst()
            .map(profileService.timelineService(profileCollection:))
            .map { CollectionItemsViewModel(collectionService: $0, identification: identification) }
            .sink { [weak self] in
                guard let self = self else { return }

                self.collectionViewModel.send($0)
                $0.$alertItem.assign(to: &self.$alertItem)
            }
            .store(in: &cancellables)
    }
}

public extension ProfileViewModel {
    func presentHeader() {
        guard let accountViewModel = accountViewModel else { return }

        imagePresentationsSubject.send(accountViewModel.headerURL)
    }

    func presentAvatar() {
        guard let accountViewModel = accountViewModel else { return }

        imagePresentationsSubject.send(accountViewModel.avatarURL(profile: true))
    }

    func fetchProfile() -> AnyPublisher<Never, Never> {
        profileService.fetchProfile().assignErrorsToAlertItem(to: \.alertItem, on: self)
    }
}

extension ProfileViewModel: CollectionViewModel {
    public var updates: AnyPublisher<CollectionUpdate, Never> {
        collectionViewModel.flatMap(\.updates).eraseToAnyPublisher()
    }

    public var title: AnyPublisher<String, Never> {
        $accountViewModel.compactMap { $0?.accountName }.eraseToAnyPublisher()
    }

    public var titleLocalizationComponents: AnyPublisher<[String], Never> {
        collectionViewModel.flatMap(\.titleLocalizationComponents).eraseToAnyPublisher()
    }

    public var expandAll: AnyPublisher<ExpandAllState, Never> {
        Empty().eraseToAnyPublisher()
    }

    public var alertItems: AnyPublisher<AlertItem, Never> {
        collectionViewModel.flatMap(\.alertItems).eraseToAnyPublisher()
    }

    public var loading: AnyPublisher<Bool, Never> {
        collectionViewModel.flatMap(\.loading).eraseToAnyPublisher()
    }

    public var events: AnyPublisher<CollectionItemEvent, Never> {
        $accountViewModel.compactMap { $0 }
            .flatMap(\.events)
            .flatMap { $0 }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .merge(with: collectionViewModel.flatMap(\.events))
            .eraseToAnyPublisher()
    }

    public var nextPageMaxId: String? {
        collectionViewModel.value.nextPageMaxId
    }

    public var preferLastPresentIdOverNextPageMaxId: Bool {
        collectionViewModel.value.preferLastPresentIdOverNextPageMaxId
    }

    public var canRefresh: Bool { collectionViewModel.value.canRefresh }

    public func request(maxId: String?, minId: String?) {
        if case .statuses = collection, maxId == nil {
            profileService.fetchPinnedStatuses()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
        }

        collectionViewModel.value.request(maxId: maxId, minId: minId)
    }

    public func viewedAtTop(indexPath: IndexPath) {
        collectionViewModel.value.viewedAtTop(indexPath: indexPath)
    }

    public func select(indexPath: IndexPath) {
        collectionViewModel.value.select(indexPath: indexPath)
    }

    public func canSelect(indexPath: IndexPath) -> Bool {
        collectionViewModel.value.canSelect(indexPath: indexPath)
    }

    public func viewModel(indexPath: IndexPath) -> CollectionItemViewModel {
        collectionViewModel.value.viewModel(indexPath: indexPath)
    }

    public func toggleExpandAll() {
        collectionViewModel.value.toggleExpandAll()
    }
}
