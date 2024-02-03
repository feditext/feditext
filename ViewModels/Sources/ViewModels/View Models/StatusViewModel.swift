// Copyright © 2020 Metabolist. All rights reserved.

import AppUrls
import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import ServiceLayer

public final class StatusViewModel: AttachmentsRenderingViewModel, ObservableObject {
    public let accountViewModel: AccountViewModel
    public let content: NSAttributedString
    public let contentEmojis: [Emoji]
    public let spoilerText: String
    public let isReblog: Bool
    public let rebloggedByDisplayName: String
    public let rebloggedByDisplayNameEmojis: [Emoji]
    public let attachmentViewModels: [AttachmentViewModel]
    public let pollEmojis: [Emoji]
    @Published public var pollOptionSelections = Set<Int>()
    public var configuration = CollectionItem.StatusConfiguration.default
    public var showReportSelectionToggle = false
    public var selectedForReport = false
    public let identityContext: IdentityContext

    private let statusService: StatusService
    private let eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>

    init(statusService: StatusService,
         identityContext: IdentityContext,
         eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>) {
        self.statusService = statusService
        self.identityContext = identityContext
        self.eventsSubject = eventsSubject
        accountViewModel = AccountViewModel(
            accountService: statusService.navigationService
                .accountService(account: statusService.status.displayStatus.account),
            identityContext: identityContext,
            eventsSubject: eventsSubject)
        content = statusService.status.displayStatus.content.attributed
        contentEmojis = statusService.status.displayStatus.emojis
        spoilerText = statusService.status.displayStatus.spoilerText
        // Quotes also contain reblog info (at least in Firefish) but should not be displayed as reblogs.
        isReblog = statusService.status.reblog != nil && statusService.status.quote == nil
        rebloggedByDisplayName = statusService.status.account.displayName.isEmpty
            ? statusService.status.account.username
            : statusService.status.account.displayName
        rebloggedByDisplayNameEmojis = statusService.status.account.emojis
        attachmentViewModels = statusService.status.displayStatus.mediaAttachments
            .map { AttachmentViewModel(attachment: $0, identityContext: identityContext, status: statusService.status) }
        pollEmojis = statusService.status.displayStatus.poll?.emojis ?? []
    }

    /// Fold statuses more than this many characters long.
    /// Based on character count in parsed plain text of status.
    public static let foldCharacterLimit: Int = 1000

    /// Fold statuses with more than this many lines in the first `foldCharacterLimit` characters.
    /// Based on newline count in parsed plain text of status.
    public static let foldNewlineLimit: Int = 10
}

public extension StatusViewModel {
    /// View model for the status that this status is quoting, if there is one.
    var quoted: Self? {
        guard let quotedService = statusService.quoted else { return nil }

        return Self(
            statusService: quotedService,
            identityContext: identityContext,
            eventsSubject: eventsSubject
        )
    }

    /// Navigate to the displayed status.
    /// Only makes sense if we're not the currently focused status, such as if we are a quoted status.
    func presentDisplayStatus() {
        eventsSubject.send(
            Just(
                .navigation(
                    .collection(
                        statusService.navigationService.contextService(
                            id: statusService.status.displayStatus.id
                        )
                    )
                )
            )
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        )
    }

    var isMine: Bool { statusService.status.displayStatus.account.id == identityContext.identity.account?.id }

    var mentionsMe: Bool {
        guard let myId = identityContext.identity.account?.id else { return false }

        return statusService.status.displayStatus.mentions.contains { $0.id == myId }
    }

    /// Does this instance support editing statuses?
    var canEditStatuses: Bool {
        StatusEndpoint.put(
            id: "",
            .init(
                inReplyToId: nil,
                text: "",
                spoilerText: "",
                mediaIds: [],
                visibility: nil,
                language: nil,
                sensitive: false,
                pollOptions: [],
                pollExpiresIn: 0,
                pollMultipleChoice: false
            )
        )
        .canCallWith(identityContext.apiCapabilities)
    }

    var showContentToggled: Bool {
        configuration.showContentToggled
    }

    var hasSpoiler: Bool {
        !spoilerText.isEmpty
    }

    var alwaysExpandSpoilers: Bool {
        identityContext.identity.preferences.readingExpandSpoilers
    }

    var shouldHideDueToSpoiler: Bool {
        guard !alwaysExpandSpoilers else {
            return false
        }

        return hasSpoiler
    }

    var foldLongContent: Bool {
        identityContext.appPreferences.foldLongPosts
    }

    var hasLongContent: Bool {
        let plainTextContent = statusService.status.displayStatus.content.attributed.string
        if plainTextContent.count > Self.foldCharacterLimit {
            return true
        }
        let newlineCount = plainTextContent.prefix(Self.foldCharacterLimit).filter { $0.isNewline }.count
        return newlineCount > Self.foldNewlineLimit
    }

    var shouldHideDueToLongContent: Bool {
        foldLongContent && hasLongContent
    }

    var shouldShowContentWarningButton: Bool {
        if self.showContentToggled {
            return !identityContext.appPreferences.hideContentWarningButton
        } else {
            return true
        }
    }

    var shouldShowContent: Bool {
        guard shouldHideDueToSpoiler || shouldHideDueToLongContent else {
            return true
        }

        return showContentToggled
    }

    var shouldShowContentPreview: Bool {
        shouldHideDueToLongContent
            && !shouldHideDueToSpoiler
            && !shouldShowContent
    }

    var shouldShowAttachments: Bool {
        switch identityContext.identity.preferences.readingExpandMedia {
        case .default, .unknown:
            return !sensitive || configuration.showAttachmentsToggled
        case .showAll:
            return !configuration.showAttachmentsToggled
        case .hideAll:
            return configuration.showAttachmentsToggled
        }
    }

    var shouldShowHideAttachmentsButton: Bool {
        sensitive || identityContext.identity.preferences.readingExpandMedia == .hideAll
    }

    var id: Status.Id { statusService.status.displayStatus.id }

    var accountName: String { "@".appending(statusService.status.displayStatus.account.acct) }

    var avatarURL: URL? {
        if identityContext.appPreferences.animateAvatars == .everywhere {
            return statusService.status.displayStatus.account.avatar.url
        } else {
            return statusService.status.displayStatus.account.unifiedAvatarStatic.url
        }
    }

    var rebloggerAvatarURL: URL? {
        if identityContext.appPreferences.animateAvatars == .everywhere {
            return statusService.status.account.avatar.url
        } else {
            return statusService.status.account.unifiedAvatarStatic.url
        }
    }

    var time: String? { statusService.status.displayStatus.lastModified.timeAgo }

    var accessibilityTime: String? { statusService.status.displayStatus.lastModified.accessibilityTimeAgo }

    var canViewEditHistory: Bool {
        StatusEditsEndpoint.history(id: "").canCallWith(identityContext.apiCapabilities)
    }

    var edited: Bool { statusService.status.displayStatus.edited }

    var contextParentTime: String {
        Self.contextParentDateFormatter.string(from: statusService.status.displayStatus.createdAt)
    }

    var contextParentEditedTime: String? {
        statusService.status.displayStatus.editedAt.map { Self.contextParentDateFormatter.string(from: $0) }
    }

    var accessibilityContextParentTime: String {
        Self.contextParentAccessibilityDateFormatter.string(from: statusService.status.displayStatus.createdAt)
    }

    var accessibilityContextParentEditedTime: String? {
        statusService.status.displayStatus.editedAt
            .map { Self.contextParentAccessibilityDateFormatter.string(from: $0) }
    }

    var applicationName: String? { statusService.status.displayStatus.application?.name }

    var applicationURL: URL? {
        guard let website = statusService.status.displayStatus.application?.website else { return nil }

        return URL(string: website)
    }

    var mentions: [Mention] { statusService.status.displayStatus.mentions }

    var visibility: Status.Visibility { statusService.status.displayStatus.visibility }

    var repliesCount: Int { statusService.status.displayStatus.repliesCount }

    var reblogsCount: Int { statusService.status.displayStatus.reblogsCount }

    var favoritesCount: Int { statusService.status.displayStatus.favouritesCount }

    var reblogged: Bool { statusService.status.displayStatus.reblogged }

    var favorited: Bool { statusService.status.displayStatus.favourited }

    var bookmarked: Bool { statusService.status.displayStatus.bookmarked }

    var sensitive: Bool { statusService.status.displayStatus.sensitive }

    var pinned: Bool? { statusService.status.displayStatus.pinned }

    var muted: Bool { statusService.status.displayStatus.muted }

    var sharingURL: URL? {
        guard let urlString = statusService.status.displayStatus.url else { return nil }

        return URL(string: urlString)
    }

    var isPollExpired: Bool { statusService.status.displayStatus.poll?.expired ?? true }

    var hasVotedInPoll: Bool { statusService.status.displayStatus.poll?.voted ?? false }

    var isPollMultipleSelection: Bool { statusService.status.displayStatus.poll?.multiple ?? false }

    var pollOptions: [Poll.Option] { statusService.status.displayStatus.poll?.options ?? [] }

    var pollVotersCount: Int {
        guard let poll = statusService.status.displayStatus.poll else { return 0 }

        return poll.votersCount ?? poll.votesCount
    }

    var pollOwnVotes: Set<Int> { Set(statusService.status.displayStatus.poll?.ownVotes ?? []) }

    var pollTimeLeft: String? {
        guard let expiresAt = statusService.status.displayStatus.poll?.expiresAt,
              expiresAt > Date()
        else { return nil }

        return expiresAt.fullUnitTimeUntil
    }

    var cardViewModel: CardViewModel? {
        if let card = statusService.status.displayStatus.card {
            return CardViewModel(card: card)
        } else {
            return nil
        }
    }

    var canBeReblogged: Bool {
        switch statusService.status.displayStatus.visibility {
        case .direct:
            return false
        case .private:
            return isMine
        default:
            return true
        }
    }

    var tagViewModels: [TagViewModel] {
        statusService.status.displayStatus.tags.map {
            .init(
                tag: $0,
                identityContext: identityContext
            )
        }
    }

    func toggleShowContent() {
        eventsSubject.send(
            statusService.toggleShowContent()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func toggleShowAttachments() {
        eventsSubject.send(
            statusService.toggleShowAttachments()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func tagSelected(_ id: TagViewModel.ID) {
        eventsSubject.send(
            Just(
                .navigation(
                    .collection(
                        statusService.navigationService.timelineService(
                            timeline: .tag(id)
                        )
                    )
                )
            )
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        )
    }

    func urlSelected(_ url: URL) {
        let urlString = url.absoluteString
        if urlString == statusService.status.uri || urlString == statusService.status.url {
            // Special case: if we try to navigate to a URL that's the same as this status's,
            // the status is most likely a non-Note AP activity which has been rendered
            // by the server as a status containing a link to the original.
            // This is really common for blog articles.
            // The correct behavior in this case is to open it in the browser.
            eventsSubject.send(
                Just(.navigation(.url(url)))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            )
        } else {
            eventsSubject.send(
                statusService.navigationService.lookup(url: url, identityId: identityContext.identity.id)
                    .map { .navigation($0) }
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher())
        }
    }

    func accountSelected() {
        eventsSubject.send(
            Just(.navigation(
                    .profile(
                        statusService.navigationService.profileService(
                            account: statusService.status.displayStatus.account))))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func rebloggerAccountSelected() {
        eventsSubject.send(
            Just(.navigation(
                    .profile(
                        statusService.navigationService.profileService(
                            account: statusService.status.account))))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func rebloggedBySelected() {
        eventsSubject.send(
            Just(.navigation(.collection(statusService.rebloggedByService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func favoritedBySelected() {
        eventsSubject.send(
            Just(.navigation(.collection(statusService.favoritedByService())))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func reply(identity: Identity? = nil) {
        if let identity = identity {
            let identityContext = self.identityContext
            let configuration = self.configuration.reply()

            eventsSubject.send(statusService.asIdentity(id: identity.id).map {
                let replyViewModel = Self(statusService: $0,
                                          identityContext: identityContext,
                                          eventsSubject: .init())

                replyViewModel.configuration = configuration

                return CollectionItemEvent.compose(identity: identity, inReplyTo: replyViewModel)
            }
            .eraseToAnyPublisher())
        } else {
            let replyViewModel = Self(statusService: statusService,
                                      identityContext: identityContext,
                                      eventsSubject: .init())

            replyViewModel.configuration = configuration.reply()

            eventsSubject.send(
                Just(.compose(inReplyTo: replyViewModel))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher())
        }
    }

    func toggleReblogged(identityId: Identity.Id? = nil) {
        eventsSubject.send(
            statusService.toggleReblogged(identityId: identityId)
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func toggleFavorited(identityId: Identity.Id? = nil) {
        eventsSubject.send(
            statusService.toggleFavorited(identityId: identityId)
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func toggleBookmarked() {
        eventsSubject.send(
            statusService.toggleBookmarked()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func togglePinned() {
        eventsSubject.send(
            statusService.togglePinned()
                .collect()
                .map { _ in .refresh }
                .eraseToAnyPublisher())
    }

    func toggleMuted() {
        eventsSubject.send(
            statusService.toggleMuted()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func confirmDelete(redraft: Bool) {
        eventsSubject.send(
            Just(.confirmDelete(self, redraft: redraft))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func delete() {
        let isContextParent = configuration.isContextParent

        eventsSubject.send(
            statusService.delete()
                .map { _ in isContextParent ? .contextParentDeleted : .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func deleteAndRedraft() {
        compose(
            statusService.deleteAndRedraft()
                .map { status in ComposeOperation.redraft(status) }
                .eraseToAnyPublisher()
        )
    }

    func edit() {
        compose(
            statusService.withSource()
                .map { status in ComposeOperation.edit(status) }
                .eraseToAnyPublisher()
        )
    }

    func attachmentSelected(viewModel: AttachmentViewModel) {
        if viewModel.attachment.type == .unknown, let remoteUrl = viewModel.attachment.remoteUrl?.url {
            urlSelected(remoteUrl)
        } else {
            eventsSubject.send(Just(.attachment(viewModel, self)).setFailureType(to: Error.self).eraseToAnyPublisher())
        }
    }

    func shareStatus() {
        guard let urlString = statusService.status.displayStatus.url,
              let url = URL(string: urlString)
              else { return }

        eventsSubject.send(Just(.share(url)).setFailureType(to: Error.self).eraseToAnyPublisher())
    }

    func reportStatus() {
        eventsSubject.send(
            Just(.report(ReportViewModel(
                            accountService: statusService.navigationService.accountService(
                                account: statusService.status.displayStatus.account),
                            statusId: statusService.status.displayStatus.id,
                            identityContext: identityContext)))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func vote() {
        eventsSubject.send(
            statusService.vote(selectedOptions: pollOptionSelections)
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func refreshPoll() {
        eventsSubject.send(
            statusService.refreshPoll()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func presentHistory() {
        let identityContext = identityContext
        let navigationService = statusService.navigationService
        let eventsSubject = eventsSubject
        eventsSubject.send(
            statusService.history()
                .map { history in .presentHistory(
                        StatusHistoryViewModel(
                            identityContext: identityContext,
                            navigationService: navigationService,
                            eventsSubject: eventsSubject,
                            history: history
                        )
                    )
                }
                .eraseToAnyPublisher()
        )
    }

    /// Emoji reactions.
    var reactions: [Reaction] { statusService.status.displayStatus.unifiedReactions }

    var canEditReactions: Bool { statusService.canEditReactions }

    /// Some instances have a cap on the number of reactions you can use.
    var canAddMoreReactions: Bool {
        if let maxReactions = identityContext.identity.instance?.maxReactions {
            let numOwnReactions = reactions.filter { $0.me }.count
            if numOwnReactions >= maxReactions {
                return false
            }
        }
        return true
    }

    /// Pick an emoji reaction to add.
    func presentEmojiPicker(sourceViewTag: Int) {
        eventsSubject.send(
            Just(
                .presentEmojiPicker(
                    sourceViewTag: sourceViewTag,
                    selectionAction: { [weak self] in
                        self?.addReaction(name: $0)
                    }
                )
            )
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        )
    }

    /// Add an emoji reaction.
    func addReaction(name: String) {
        eventsSubject.send(
            statusService
                .addReaction(name: name)
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher()
        )
    }

    /// Remove an emoji reaction.
    func removeReaction(name: String) {
        eventsSubject.send(
            statusService
                .removeReaction(name: name)
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher()
        )
    }
}

private extension StatusViewModel {
    private static let contextParentDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        return dateFormatter
    }()

    private static let contextParentAccessibilityDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        return dateFormatter
    }()

    enum ComposeOperation {
        case redraft(Status)
        case edit(Status)

        var redraft: Status? {
            switch self {
            case let .redraft(status):
                return status
            case .edit:
                return nil
            }
        }

        var edit: Status? {
            switch self {
            case .redraft:
                return nil
            case let .edit(status):
                return status
            }
        }
    }

    /// Common across delete-redraft and edit actions.
    func compose(_ operationPublisher: AnyPublisher<ComposeOperation, Error>) {
        let identityContext = identityContext
        let isContextParent = configuration.isContextParent

        let eventPublisher = operationPublisher
            .zip(statusService.inReplyTo())
            .map { operation, inReplyToStatusService in
                let inReplyToViewModel = inReplyToStatusService.map { statusService in
                    let viewModel = Self(
                        statusService: statusService,
                        identityContext: identityContext,
                        eventsSubject: .init()
                    )
                    viewModel.configuration = CollectionItem.StatusConfiguration.default.reply()
                    return viewModel
                }

                return CollectionItemEvent.compose(
                    inReplyTo: inReplyToViewModel,
                    redraft: operation.redraft,
                    edit: operation.edit,
                    wasContextParent: isContextParent
                )
            }
            .eraseToAnyPublisher()

        eventsSubject.send(eventPublisher)
    }
}
