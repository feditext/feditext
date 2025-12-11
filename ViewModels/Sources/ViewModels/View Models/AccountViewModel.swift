// Copyright © 2020 Metabolist. All rights reserved.

import AppUrls
import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import ServiceLayer

public final class AccountViewModel: ObservableObject {
  public let identityContext: IdentityContext
  public internal(set) var configuration = CollectionItem.AccountConfiguration.withNote
  public internal(set) var relationship: Relationship?
  public internal(set) var familiarFollowers = [Account]()
  public internal(set) var suggestionSource: Suggestion.Source?
  public internal(set) var identityProofs = [IdentityProof]()
  public internal(set) var featuredTags = [FeaturedTag]()

  internal let accountService: AccountService
  private let eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>

  init(
    accountService: AccountService,
    identityContext: IdentityContext,
    eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>
  ) {
    self.accountService = accountService
    self.identityContext = identityContext
    self.eventsSubject = eventsSubject
  }
}

extension AccountViewModel {
  public var id: Account.Id { accountService.account.id }

  public var headerURL: URL? {
    if identityContext.appPreferences.animateHeaders {
      return accountService.account.header.url
    } else {
      return accountService.account.unifiedHeaderStatic.url
    }
  }

  public var isLocal: Bool { accountService.isLocal }

  public var domain: String? { accountService.domain }

  public var displayName: String {
    accountService.account.displayName.isEmpty ? accountService.account.acct : accountService.account.displayName
  }

  public var accountName: String { "@".appending(accountService.account.acct) }

  public var movedAccountName: String? {
    guard let moved = accountService.account.moved else { return nil }

    return "@".appending(moved.acct)
  }

  public var isLocked: Bool { accountService.account.locked }

  public var statusesCount: Int { accountService.account.statusesCount }

  public var joined: Date { accountService.account.createdAt }

  public var fields: [Account.Field] { accountService.account.fields }

  public var note: AttributedString { accountService.account.note.attrStr }

  public var emojis: [Emoji] { accountService.account.emojis }

  public var followingCount: Int { accountService.account.followingCount }

  public var followersCount: Int { accountService.account.followersCount }

  public var isSelf: Bool { accountService.account.id == identityContext.identity.account?.id }

  public var isBot: Bool { accountService.account.bot }

  public var isGroup: Bool { accountService.account.group }

  public var accountTypeText: String {
    if isBot && isGroup {
      return NSLocalizedString("account.type.bot-group", comment: "")
    } else if isBot {
      return NSLocalizedString("account.type.bot", comment: "")
    } else if isGroup {
      return NSLocalizedString("account.type.group", comment: "")
    } else {
      return ""
    }
  }

  public var suggestionSourceText: String {
    guard let suggestionSource = suggestionSource else { return "" }
    switch suggestionSource {
    case .global:
      return NSLocalizedString("account.type.group", comment: "")
    case .pastInteractions:
      return NSLocalizedString("account.type.group", comment: "")
    case .staff:
      return NSLocalizedString("account.type.group", comment: "")
    case .unknown:
      return ""
    }
  }

  public func avatarURL(profile: Bool = false) -> URL? {
    if identityContext.appPreferences.animateAvatars == .everywhere
      || (identityContext.appPreferences.animateAvatars == .profiles && profile)
    {
      return accountService.account.avatar.url
    } else {
      return accountService.account.unifiedAvatarStatic.url
    }
  }

  public func urlSelected(_ url: URL) {
    eventsSubject.send(
      accountService.navigationService.lookup(url: url, identityId: identityContext.identity.id)
        .map { CollectionItemEvent.navigation($0) }
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    )
  }

  public func followingSelected() {
    eventsSubject.send(
      Just(.navigation(.collection(accountService.followingService())))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    )
  }

  public func followersSelected() {
    eventsSubject.send(
      Just(.navigation(.collection(accountService.followersService())))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    )
  }

  public func familiarFollowersSelected() {
    eventsSubject.send(
      Just(
        .navigation(
          .collection(
            identityContext
              .service
              .navigationService
              .familiarFollowersService(
                familiarFollowers: familiarFollowers
              )
          )
        )
      )
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    )
  }

  /// If migrated, navigate to the new account.
  public func movedSelected() {
    guard let moved = accountService.account.moved else { return }

    eventsSubject.send(
      Just(
        .navigation(
          .profile(
            identityContext
              .service
              .navigationService
              .profileService(id: moved.id)
          )
        )
      )
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    )
  }

  public func reportViewModel() -> ReportViewModel {
    ReportViewModel(accountService: accountService, identityContext: identityContext)
  }

  public func muteViewModel() -> MuteViewModel {
    MuteViewModel(accountService: accountService, identityContext: identityContext)
  }

  public var canAddToList: Bool {
    EmptyEndpoint.addAccountsToList(id: "", accountIds: []).canCallWith(identityContext.apiCapabilities)
  }

  public func lists() -> AnyPublisher<[List], Error> {
    accountService.lists()
  }

  public func addToList(id: List.Id) -> AnyPublisher<Never, Error> {
    accountService.addToList(id: id)
  }

  public func removeFromList(id: List.Id) -> AnyPublisher<Never, Error> {
    accountService.removeFromList(id: id)
  }

  public func follow() {
    ignorableOutputEvent(accountService.follow())
  }

  public func confirmUnfollow() {
    eventsSubject.send(Just(.confirmUnfollow(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func unfollow() {
    ignorableOutputEvent(accountService.unfollow())
  }

  public func share() {
    guard let url = URL(string: accountService.account.url) else { return }

    eventsSubject.send(Just(.share(url)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func confirmHideReblogs() {
    eventsSubject.send(Just(.confirmHideReblogs(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func hideReblogs() {
    ignorableOutputEvent(accountService.hideReblogs())
  }

  public func confirmShowReblogs() {
    eventsSubject.send(Just(.confirmShowReblogs(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func showReblogs() {
    ignorableOutputEvent(accountService.showReblogs())
  }

  public func notify() {
    ignorableOutputEvent(accountService.notify())
  }

  public func unnotify() {
    ignorableOutputEvent(accountService.unnotify())
  }

  public func confirmBlock() {
    eventsSubject.send(Just(.confirmBlock(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func block() {
    ignorableOutputEvent(accountService.block())
  }

  public func confirmUnblock() {
    eventsSubject.send(Just(.confirmUnblock(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func unblock() {
    ignorableOutputEvent(accountService.unblock())
  }

  public var canMute: Bool {
    RelationshipEndpoint.accountsMute(id: "").canCallWith(identityContext.apiCapabilities)
  }

  public func confirmMute() {
    eventsSubject.send(Just(.confirmMute(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func confirmUnmute() {
    eventsSubject.send(Just(.confirmUnmute(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func unmute() {
    ignorableOutputEvent(accountService.unmute())
  }

  public func pin() {
    ignorableOutputEvent(accountService.pin())
  }

  public func unpin() {
    ignorableOutputEvent(accountService.unpin())
  }

  public var canEditNotes: Bool {
    RelationshipEndpoint.note("", id: "").canCallWith(identityContext.apiCapabilities)
  }

  public func editNote() {
    eventsSubject.send(Just(.editNote(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func set(note: String) {
    ignorableOutputEvent(accountService.set(note: note))
  }

  public func acceptFollowRequest() {
    accountListEdit(accountService.acceptFollowRequest(), event: .acceptFollowRequest)
  }

  public func rejectFollowRequest() {
    accountListEdit(accountService.rejectFollowRequest(), event: .rejectFollowRequest)
  }

  public func removeFollowSuggestion() {
    accountListEdit(accountService.removeFollowSuggestion(), event: .removeFollowSuggestion)
  }

  public var canBlockDomains: Bool {
    EmptyEndpoint.blockDomain("").canCallWith(identityContext.apiCapabilities)
  }

  public func confirmDomainBlock(domain: String) {
    eventsSubject.send(Just(.confirmDomainBlock(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func domainBlock() {
    ignorableOutputEvent(accountService.domainBlock())
  }

  public func confirmDomainUnblock(domain: String) {
    eventsSubject.send(Just(.confirmDomainUnblock(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
  }

  public func domainUnblock() {
    ignorableOutputEvent(accountService.domainUnblock())
  }
}

extension AccountViewModel {
  fileprivate func ignorableOutputEvent(_ action: AnyPublisher<Never, Error>) {
    eventsSubject.send(action.map { _ in .ignorableOutput }.eraseToAnyPublisher())
  }

  fileprivate func accountListEdit(_ action: AnyPublisher<Never, Error>, event: CollectionItemEvent.AccountListEdit) {
    eventsSubject.send(
      action.collect()
        .map { [weak self] _ -> CollectionItemEvent in
          guard let self = self else { return .ignorableOutput }

          return .accountListEdit(self, event)
        }
        .eraseToAnyPublisher()
    )
  }
}
