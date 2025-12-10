// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import MastodonAPI
import ServiceLayer

public final class PreferencesViewModel: ObservableObject {
  @Published public var preferences: Identity.Preferences
  @Published public var alertItem: AlertItem?
  public let shouldShowNotificationTypePreferences: Bool
  public let identityContext: IdentityContext

  private var cancellables = Set<AnyCancellable>()

  public init(identityContext: IdentityContext) {
    self.identityContext = identityContext

    shouldShowNotificationTypePreferences = identityContext.identity.lastRegisteredDeviceToken != nil
    preferences = identityContext.identity.preferences

    identityContext.$identity
      .map(\.preferences)
      .dropFirst()
      .removeDuplicates()
      .assign(to: &$preferences)

    $preferences
      .dropFirst()
      .flatMap {
        identityContext.service.updatePreferences(
          $0,
          authenticated: identityContext.identity.authenticated)
      }
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .sink { _ in }
      .store(in: &cancellables)
  }
}

extension PreferencesViewModel {
  public var canListMutedUsers: Bool {
    AccountsEndpoint.mutes.canCallWith(identityContext.apiCapabilities)
  }

  public func mutedUsersViewModel() -> CollectionViewModel {
    CollectionItemsViewModel(
      collectionService: identityContext.service.service(accountList: .mutes),
      identityContext: identityContext)
  }

  public func blockedUsersViewModel() -> CollectionViewModel {
    CollectionItemsViewModel(
      collectionService: identityContext.service.service(accountList: .blocks),
      identityContext: identityContext)
  }

  public var canListDomainBlocks: Bool {
    StringsEndpoint.domainBlocks.canCallWith(identityContext.apiCapabilities)
  }

  public func domainBlocksViewModel() -> DomainBlocksViewModel {
    DomainBlocksViewModel(service: identityContext.service.domainBlocksService())
  }
}
