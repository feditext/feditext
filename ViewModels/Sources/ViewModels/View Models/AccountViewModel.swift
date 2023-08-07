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

    init(accountService: AccountService,
         identityContext: IdentityContext,
         eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>) {
        self.accountService = accountService
        self.identityContext = identityContext
        self.eventsSubject = eventsSubject
    }
}

public extension AccountViewModel {
    var id: Account.Id { accountService.account.id }

    var headerURL: URL? {
        if identityContext.appPreferences.animateHeaders {
            return accountService.account.header.url
        } else {
            return accountService.account.unifiedHeaderStatic.url
        }
    }

    var isLocal: Bool { accountService.isLocal }

    var domain: String? { accountService.domain }

    var displayName: String {
        accountService.account.displayName.isEmpty ? accountService.account.acct : accountService.account.displayName
    }

    var accountName: String { "@".appending(accountService.account.acct) }

    var movedAccountName: String? {
        guard let moved = accountService.account.moved else { return nil }

        return "@".appending(moved.acct)
    }

    var isLocked: Bool { accountService.account.locked }

    var statusesCount: Int { accountService.account.statusesCount }

    var joined: Date { accountService.account.createdAt }

    var fields: [Account.Field] { accountService.account.fields }

    var note: NSAttributedString { accountService.account.note.attributed }

    var emojis: [Emoji] { accountService.account.emojis }

    var followingCount: Int { accountService.account.followingCount }

    var followersCount: Int { accountService.account.followersCount }

    var isSelf: Bool { accountService.account.id == identityContext.identity.account?.id }

    var isBot: Bool { accountService.account.bot }

    var isGroup: Bool { accountService.account.group }

    var accountTypeText: String {
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

    var suggestionSourceText: String {
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

    func avatarURL(profile: Bool = false) -> URL? {
        if identityContext.appPreferences.animateAvatars == .everywhere
            || (identityContext.appPreferences.animateAvatars == .profiles && profile) {
            return accountService.account.avatar.url
        } else {
            return accountService.account.unifiedAvatarStatic.url
        }
    }

    func urlSelected(_ url: URL) {
        eventsSubject.send(
            accountService.navigationService.lookup(url: url, identityId: identityContext.identity.id)
                .map { CollectionItemEvent.navigation($0) }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func followingSelected() {
        eventsSubject.send(
            Just(.navigation(.collection(accountService.followingService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func followersSelected() {
        eventsSubject.send(
            Just(.navigation(.collection(accountService.followersService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func familiarFollowersSelected() {
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
    func movedSelected() {
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

    func reportViewModel() -> ReportViewModel {
        ReportViewModel(accountService: accountService, identityContext: identityContext)
    }

    func muteViewModel() -> MuteViewModel {
        MuteViewModel(accountService: accountService, identityContext: identityContext)
    }

    var canAddToList: Bool {
        EmptyEndpoint.addAccountsToList(id: "", accountIds: []).canCallWith(identityContext.apiCapabilities)
    }

    func lists() -> AnyPublisher<[List], Error> {
        accountService.lists()
    }

    func addToList(id: List.Id) -> AnyPublisher<Never, Error> {
        accountService.addToList(id: id)
    }

    func removeFromList(id: List.Id) -> AnyPublisher<Never, Error> {
        accountService.removeFromList(id: id)
    }

    func follow() {
        ignorableOutputEvent(accountService.follow())
    }

    func confirmUnfollow() {
        eventsSubject.send(Just(.confirmUnfollow(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func unfollow() {
        ignorableOutputEvent(accountService.unfollow())
    }

    func share() {
        guard let url = URL(string: accountService.account.url) else { return }

        eventsSubject.send(Just(.share(url)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func confirmHideReblogs() {
        eventsSubject.send(Just(.confirmHideReblogs(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func hideReblogs() {
        ignorableOutputEvent(accountService.hideReblogs())
    }

    func confirmShowReblogs() {
        eventsSubject.send(Just(.confirmShowReblogs(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func showReblogs() {
        ignorableOutputEvent(accountService.showReblogs())
    }

    func notify() {
        ignorableOutputEvent(accountService.notify())
    }

    func unnotify() {
        ignorableOutputEvent(accountService.unnotify())
    }

    func confirmBlock() {
        eventsSubject.send(Just(.confirmBlock(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func block() {
        ignorableOutputEvent(accountService.block())
    }

    func confirmUnblock() {
        eventsSubject.send(Just(.confirmUnblock(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func unblock() {
        ignorableOutputEvent(accountService.unblock())
    }

    var canMute: Bool {
        RelationshipEndpoint.accountsMute(id: "").canCallWith(identityContext.apiCapabilities)
    }

    func confirmMute() {
        eventsSubject.send(Just(.confirmMute(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func confirmUnmute() {
        eventsSubject.send(Just(.confirmUnmute(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func unmute() {
        ignorableOutputEvent(accountService.unmute())
    }

    func pin() {
        ignorableOutputEvent(accountService.pin())
    }

    func unpin() {
        ignorableOutputEvent(accountService.unpin())
    }

    var canEditNotes: Bool {
        RelationshipEndpoint.note("", id: "").canCallWith(identityContext.apiCapabilities)
    }

    func editNote() {
        eventsSubject.send(Just(.editNote(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func set(note: String) {
        ignorableOutputEvent(accountService.set(note: note))
    }

    func acceptFollowRequest() {
        accountListEdit(accountService.acceptFollowRequest(), event: .acceptFollowRequest)
    }

    func rejectFollowRequest() {
        accountListEdit(accountService.rejectFollowRequest(), event: .rejectFollowRequest)
    }

    func removeFollowSuggestion() {
        accountListEdit(accountService.removeFollowSuggestion(), event: .removeFollowSuggestion)
    }

    var canBlockDomains: Bool {
        EmptyEndpoint.blockDomain("").canCallWith(identityContext.apiCapabilities)
    }

    func confirmDomainBlock(domain: String) {
        eventsSubject.send(Just(.confirmDomainBlock(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func domainBlock() {
        ignorableOutputEvent(accountService.domainBlock())
    }

    func confirmDomainUnblock(domain: String) {
        eventsSubject.send(Just(.confirmDomainUnblock(self)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func domainUnblock() {
        ignorableOutputEvent(accountService.domainUnblock())
    }
}

private extension AccountViewModel {
    func ignorableOutputEvent(_ action: AnyPublisher<Never, Error>) {
        eventsSubject.send(action.map { _ in .ignorableOutput }.eraseToAnyPublisher())
    }

    func accountListEdit(_ action: AnyPublisher<Never, Error>, event: CollectionItemEvent.AccountListEdit) {
        eventsSubject.send(
            action.collect()
                .map { [weak self] _ -> CollectionItemEvent in
                    guard let self = self else { return .ignorableOutput }

                    return .accountListEdit(self, event)
                }
                .eraseToAnyPublisher())
    }
}
