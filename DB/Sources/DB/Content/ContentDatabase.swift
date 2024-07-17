// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import CombineInterop
import Foundation
import GRDB
import Keychain
import Mastodon
import Secrets

public struct ContentDatabase {
    public let activeFiltersPublisher: AnyPublisher<[Filter], Error>

    private let id: Identity.Id
    private let databaseWriter: DatabaseWriter
    private let useHomeTimelineLastReadId: Bool
    private let activeFilterMatchersPublisher: AnyPublisher<[Filter.Matcher], Error>

    public init(id: Identity.Id,
                useHomeTimelineLastReadId: Bool,
                inMemory: Bool,
                appGroup: String,
                keychain: Keychain.Type) throws {
        self.id = id
        self.useHomeTimelineLastReadId = useHomeTimelineLastReadId

        if inMemory {
            databaseWriter = try DatabaseQueue()
            try Self.migrator.migrate(databaseWriter)
        } else {
            databaseWriter = try DatabasePool.withFileCoordinator(
                url: Self.fileURL(id: id, appGroup: appGroup),
                migrator: Self.migrator) {
                try Secrets.databaseKey(identityId: id, keychain: keychain)
            }
        }

        activeFiltersPublisher = ValueObservation.tracking {
            try Filter.filter(Filter.Columns.expiresAt == nil || Filter.Columns.expiresAt > Date()).fetchAll($0)
        }
        .removeDuplicates()
        .publisher(in: databaseWriter)
        .eraseToAnyPublisher()

        activeFilterMatchersPublisher = activeFiltersPublisher
            .map { $0.compactMap(\.matcher) }
            .eraseToAnyPublisher()
    }
}

public extension ContentDatabase {
    static func delete(id: Identity.Id, appGroup: String) throws {
        try FileManager.default.removeItem(at: fileURL(id: id, appGroup: appGroup))
    }

    func insert(status: Status) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher(updates: status.save)
    }

    // swiftlint:disable function_body_length
    /// Store statuses and associate them with the given timeline.
    func insert(
        statuses: [Status],
        timeline: Timeline,
        loadMoreAndDirection: (LoadMore, LoadMore.Direction)? = nil
    ) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            let timelineRecord = TimelineRecord(timeline: timeline)

            try timelineRecord.save($0)

            let maxIdPresent = try String.fetchOne($0, timelineRecord.statuses.select(max(StatusRecord.Columns.id)))

            var order = timeline.ordered
                ? try Int.fetchOne(
                    $0,
                    TimelineStatusJoin.filter(TimelineStatusJoin.Columns.timelineId == timeline.id)
                        .select(max(TimelineStatusJoin.Columns.order)))
                : nil

            for status in statuses {
                try status.save($0)

                try TimelineStatusJoin(timelineId: timeline.id, statusId: status.id, order: order).save($0)

                if let filterContext = timeline.filterContext {
                    try StatusFiltered.update(status, filterContext, $0)
                }

                if let presentOrder = order {
                    order = presentOrder + 1
                }
            }

            // Remove statuses from the timeline that are in the ID range covered by the inserted statuses,
            // but not in the inserted statuses. Do not remove the actual statuses, since they may still exist
            // in other timelines.
            let statusIDs = statuses.map(\.id)
            if let minStatusID = statusIDs.min(),
               let maxStatusID = statusIDs.max() {
                try TimelineStatusJoin
                    .filter(TimelineStatusJoin.Columns.timelineId == timeline.id)
                    .filter((minStatusID...maxStatusID).contains(TimelineStatusJoin.Columns.statusId))
                    .filter(!statusIDs.contains(TimelineStatusJoin.Columns.statusId))
                    .deleteAll($0)
            }

            if let maxIdPresent = maxIdPresent,
               let minIdInserted = statuses.map(\.id).min(),
               minIdInserted > maxIdPresent {
                try LoadMoreRecord(
                    timelineId: timeline.id,
                    afterStatusId: minIdInserted,
                    beforeStatusId: maxIdPresent)
                    .save($0)
            }

            guard let (loadMore, direction) = loadMoreAndDirection else { return }

            try LoadMoreRecord(
                timelineId: loadMore.timeline.id,
                afterStatusId: loadMore.afterStatusId,
                beforeStatusId: loadMore.beforeStatusId)
                .delete($0)

            switch direction {
            case .up:
                if let maxIdInserted = statuses.map(\.id).max(), maxIdInserted < loadMore.afterStatusId {
                    try LoadMoreRecord(
                        timelineId: loadMore.timeline.id,
                        afterStatusId: loadMore.afterStatusId,
                        beforeStatusId: maxIdInserted)
                        .save($0)
                }
            case .down:
                if let minIdInserted = statuses.map(\.id).min(), minIdInserted > loadMore.beforeStatusId {
                    try LoadMoreRecord(
                        timelineId: loadMore.timeline.id,
                        afterStatusId: minIdInserted,
                        beforeStatusId: loadMore.beforeStatusId)
                        .save($0)
                }
            }
        }
    }
    // swiftlint:enable function_body_length

    func cleanHomeTimelinePublisher() -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            try NotificationRecord.deleteAll($0)
            try ConversationRecord.deleteAll($0)
            try StatusAncestorJoin.deleteAll($0)
            try StatusDescendantJoin.deleteAll($0)
            try AccountList.deleteAll($0)

            if useHomeTimelineLastReadId {
                try TimelineRecord.filter(TimelineRecord.Columns.id != Timeline.home.id).deleteAll($0)
                try StatusRecord.filter(Self.statusIdsToDeleteForPositionPreservingClean(db: $0)
                    .contains(StatusRecord.Columns.id)).deleteAll($0)
                try AccountRecord.filter(Self.accountIdsToDeleteForPositionPreservingClean(db: $0)
                    .contains(AccountRecord.Columns.id)).deleteAll($0)
            } else {
                try TimelineRecord.deleteAll($0)
                try StatusRecord.deleteAll($0)
                try AccountRecord.deleteAll($0)
            }
        }
    }

    func insert(context: Context, parentId: Status.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for (index, status) in context.ancestors.enumerated() {
                try status.save($0)
                try StatusFiltered.update(status, .thread, $0)
                try StatusAncestorJoin(parentId: parentId, statusId: status.id, order: index).save($0)
            }

            for (index, status) in context.descendants.enumerated() {
                try status.save($0)
                try StatusFiltered.update(status, .thread, $0)
                try StatusDescendantJoin(parentId: parentId, statusId: status.id, order: index).save($0)
            }

            try StatusAncestorJoin.filter(
                StatusAncestorJoin.Columns.parentId == parentId
                    && !context.ancestors.map(\.id).contains(StatusAncestorJoin.Columns.statusId))
                .deleteAll($0)

            try StatusDescendantJoin.filter(
                StatusDescendantJoin.Columns.parentId == parentId
                    && !context.descendants.map(\.id).contains(StatusDescendantJoin.Columns.statusId))
                .deleteAll($0)
        }
    }

    func insert(pinnedStatuses: [Status], accountId: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for (index, status) in pinnedStatuses.enumerated() {
                try status.save($0)
                try StatusFiltered.update(status, .account, $0)
                try AccountPinnedStatusJoin(accountId: accountId, statusId: status.id, order: index).save($0)
            }

            try AccountPinnedStatusJoin.filter(
                AccountPinnedStatusJoin.Columns.accountId == accountId
                    && !pinnedStatuses.map(\.id).contains(AccountPinnedStatusJoin.Columns.statusId))
                .deleteAll($0)
        }
    }

    func toggleShowContent(id: Status.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            if let toggle = try StatusShowContentToggle
                .filter(StatusShowContentToggle.Columns.statusId == id)
                .fetchOne($0) {
                try toggle.delete($0)
            } else {
                try StatusShowContentToggle(statusId: id).save($0)
            }
        }
    }

    func toggleShowAttachments(id: Status.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            if let toggle = try StatusShowAttachmentsToggle
                .filter(StatusShowAttachmentsToggle.Columns.statusId == id)
                .fetchOne($0) {
                try toggle.delete($0)
            } else {
                try StatusShowAttachmentsToggle(statusId: id).save($0)
            }
        }
    }

    func toggleShowFiltered(id: Status.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            if let toggle = try StatusShowFilteredToggle
                .filter(StatusShowFilteredToggle.Columns.statusId == id)
                .fetchOne($0) {
                try toggle.delete($0)
            } else {
                try StatusShowFilteredToggle(statusId: id).save($0)
            }
        }
    }

    func expand(ids: Set<Status.Id>) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for id in ids {
                try StatusShowContentToggle(statusId: id).save($0)
                try StatusShowAttachmentsToggle(statusId: id).save($0)
            }
        }
    }

    func collapse(ids: Set<Status.Id>) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            try StatusShowContentToggle
                .filter(ids.contains(StatusShowContentToggle.Columns.statusId))
                .deleteAll($0)
            try StatusShowAttachmentsToggle
                .filter(ids.contains(StatusShowContentToggle.Columns.statusId))
                .deleteAll($0)
        }
    }

    func update(id: Status.Id, poll: Poll) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            let data = try StatusRecord.databaseJSONEncoder(for: StatusRecord.Columns.poll.name).encode(poll)

            try StatusRecord.filter(StatusRecord.Columns.id == id)
                .updateAll($0, StatusRecord.Columns.poll.set(to: data))
        }
    }

    func update(id: Status.Id, source: StatusSource) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            try StatusRecord
                .filter(StatusRecord.Columns.id == id)
                .updateAll(
                    $0,
                    StatusRecord.Columns.text.set(to: source.text),
                    StatusRecord.Columns.spoilerText.set(to: source.spoilerText)
                )
        }
    }

    func delete(id: Status.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher(updates: StatusRecord.filter(StatusRecord.Columns.id == id).deleteAll)
    }

    func unfollow(id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            let statusIds = try Status.Id.fetchAll(
                $0,
                StatusRecord.filter(StatusRecord.Columns.accountId == id).select(StatusRecord.Columns.id))

            try TimelineStatusJoin.filter(
                TimelineStatusJoin.Columns.timelineId == Timeline.home.id
                    && statusIds.contains(TimelineStatusJoin.Columns.statusId))
                .deleteAll($0)
        }
    }

    func mute(id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            try StatusRecord.filter(StatusRecord.Columns.accountId == id).deleteAll($0)
            try NotificationRecord.filter(NotificationRecord.Columns.accountId == id).deleteAll($0)
        }
    }

    func block(id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher(updates: AccountRecord.filter(AccountRecord.Columns.id == id).deleteAll)
    }

    func insert(accounts: [Account], listId: AccountList.Id? = nil) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            var order: Int?

            if let listId = listId {
                try AccountList(id: listId).save($0)
                order = try Int.fetchOne(
                    $0,
                    AccountListJoin.filter(AccountListJoin.Columns.accountListId == listId)
                        .select(max(AccountListJoin.Columns.order)))
                ?? 0
            }

            for account in accounts {
                try account.save($0)

                if let listId = listId, let presentOrder = order {
                    try AccountListJoin(accountListId: listId, accountId: account.id, order: presentOrder).save($0)

                    order = presentOrder + 1
                }
            }
        }
    }

    func remove(id: Account.Id, from listId: AccountList.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher(
            updates: AccountListJoin.filter(
                AccountListJoin.Columns.accountId == id
                    && AccountListJoin.Columns.accountListId == listId)
                .deleteAll)
    }

    func remove(suggestion: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher { db in
            try SuggestionRecord
                .filter(SuggestionRecord.Columns.id == id)
                .deleteAll(db)
        }
    }

    func insert(identityProofs: [IdentityProof], id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for identityProof in identityProofs {
                try IdentityProofRecord(
                    accountId: id,
                    provider: identityProof.provider,
                    providerUsername: identityProof.providerUsername,
                    profileUrl: identityProof.profileUrl,
                    proofUrl: identityProof.proofUrl,
                    updatedAt: identityProof.updatedAt)
                    .save($0)
            }
        }
    }

    func insert(featuredTags: [FeaturedTag], id: Account.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for featuredTag in featuredTags {
                try FeaturedTagRecord(
                    id: featuredTag.id,
                    name: featuredTag.name,
                    url: featuredTag.url,
                    statusesCount: featuredTag.statusesCount,
                    lastStatusAt: featuredTag.lastStatusAt,
                    accountId: id)
                    .save($0)
            }
        }
    }

    func insert(relationships: [Relationship]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for relationship in relationships {
                try relationship.save($0)
            }
        }
    }

    func insert(familiarFollowers: [FamiliarFollowers]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for followedAccount in familiarFollowers {
                var followingAccountIds: [Account.Id] = []

                for followingAccount in followedAccount.accounts {
                    followingAccountIds.append(followingAccount.id)
                    try followingAccount.save($0)

                    try FamiliarFollowersJoin(
                        followedAccountId: followedAccount.id,
                        followingAccountId: followingAccount.id
                    ).save($0)
                }

                try FamiliarFollowersJoin
                    .filter(FamiliarFollowersJoin.Columns.followedAccountId == followedAccount.id
                            && !followingAccountIds.contains(FamiliarFollowersJoin.Columns.followingAccountId))
                    .deleteAll($0)
            }
        }
    }

    func setLists(_ lists: [List]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for list in lists {
                try TimelineRecord(timeline: Timeline.list(list)).save($0)
            }

            try TimelineRecord
                .filter(!lists.map(\.id).contains(TimelineRecord.Columns.listId)
                            && TimelineRecord.Columns.listTitle != nil)
                .deleteAll($0)
        }
    }

    func createList(_ list: List) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher { try TimelineRecord(timeline: Timeline.list(list)).save($0) }
    }

    func updateList(_ list: List) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            try TimelineRecord
                .filter(TimelineRecord.Columns.listId == list.id)
                .updateAll(
                    $0,
                    TimelineRecord.Columns.listTitle.set(to: list.title),
                    TimelineRecord.Columns.listRepliesPolicy.set(to: list.repliesPolicy?.rawValue),
                    TimelineRecord.Columns.listExclusive.set(to: list.exclusive)
                )
        }
    }

    func deleteList(id: List.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher(updates: TimelineRecord.filter(TimelineRecord.Columns.listId == id).deleteAll)
    }

    func setFilters(_ filters: [Filter]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for filter in filters {
                try filter.save($0)
            }

            try Filter.filter(!filters.map(\.id).contains(Filter.Columns.id)).deleteAll($0)
        }
    }

    func createFilter(_ filter: Filter) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher { try filter.save($0) }
    }

    func deleteFilter(id: Filter.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher(updates: Filter.filter(Filter.Columns.id == id).deleteAll)
    }

    func setFollowedTags(_ tags: [FollowedTag]) -> AnyPublisher<Never, Error> {
        return databaseWriter.mutatingPublisher {
            for tag in tags {
                try tag.save($0)
            }

            try FollowedTag
                .filter(!tags.map(\.name).contains(FollowedTag.Columns.name))
                .deleteAll($0)
        }
    }

    func createFollowedTag(_ tag: FollowedTag) -> AnyPublisher<Never, Error> {
        return databaseWriter.mutatingPublisher { try tag.save($0) }
    }

    func deleteFollowedTag(_ tag: FollowedTag) -> AnyPublisher<Never, Error> {
        return databaseWriter.mutatingPublisher(
            updates: FollowedTag
                .filter(FollowedTag.Columns.name == tag.name)
                .deleteAll
        )
    }

    func setLastReadId(_ id: String, timelineId: Timeline.Id) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher { try LastReadIdRecord(timelineId: timelineId, id: id).save($0) }
    }

    func insert(notifications: [MastodonNotification]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for notification in notifications {
                try notification.save($0)
            }
        }
    }

    func insert(conversations: [Conversation]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for conversation in conversations {
                try conversation.save($0)
            }
        }
    }

    func update(instance: Instance) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            try instance.save($0)
            try updateRules(rules: instance.rules, db: $0)
        }
    }

    func update(emojis: [Emoji]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for emoji in emojis {
                try emoji.save($0)
            }

            try Emoji.filter(!emojis.map(\.shortcode).contains(Emoji.Columns.shortcode)).deleteAll($0)
        }
    }

    func updateUse(emoji: String, system: Bool) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            let count = try Int.fetchOne(
                $0,
                EmojiUse.filter(EmojiUse.Columns.system == system && EmojiUse.Columns.emoji == emoji)
                    .select(EmojiUse.Columns.count))

            try EmojiUse(emoji: emoji, system: system, lastUse: Date(), count: (count ?? 0) + 1).save($0)
        }
    }

    func update(announcements: [Announcement]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for announcement in announcements {
                try announcement.save($0)
            }

            try Announcement.filter(!announcements.map(\.id).contains(Announcement.Columns.id)).deleteAll($0)
        }
    }

    func update(rules: [Rule]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            try updateRules(rules: rules, db: $0)
        }
    }

    private func updateRules(rules: [Rule], db: Database) throws {
        for rule in rules {
            try rule.save(db)
        }

        try Rule.filter(!rules.map(\.id).contains(Rule.Columns.id)).deleteAll(db)
    }

    func update(suggestions: [Suggestion]) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher { db in
            for suggestion in suggestions {
                try suggestion.save(db)
            }

            try SuggestionRecord
                .filter(!suggestions.map(\.account.id).contains(SuggestionRecord.Columns.id))
                .deleteAll(db)
        }
    }

    /// Store accounts and statuses from search results.
    /// Tags are currently not stored.
    func insert(results: Results) -> AnyPublisher<Never, Error> {
        databaseWriter.mutatingPublisher {
            for account in results.accounts {
                try account.save($0)
            }

            for status in results.statuses {
                try status.save($0)
            }
        }
    }

    /// Retrieve the contents of a timeline.
    func timelinePublisher(_ timeline: Timeline, applyV1Filters: Bool) -> AnyPublisher<[CollectionSection], Error> {
        ValueObservation.tracking(
            TimelineItemsInfo.request(
                TimelineRecord.filter(TimelineRecord.Columns.id == timeline.id),
                timeline.filterContext,
                ordered: timeline.ordered
            ).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .handleEvents(
                receiveSubscription: { _ in
                    if let ephemeralityId = timeline.ephemeralityId(id: id) {
                        Self.ephemeralTimelines.add(ephemeralityId)
                    }
                },
                receiveCancel: {
                    guard let ephemeralityId = timeline.ephemeralityId(id: id) else { return }

                    Self.ephemeralTimelines.remove(ephemeralityId)

                    if Self.ephemeralTimelines.count(for: ephemeralityId) == 0 {
                        databaseWriter.asyncWrite(TimelineRecord(timeline: timeline).delete) { _, _ in }
                    }
                })
            .combineLatest(activeFilterMatchersPublisher)
            .compactMap { $0?.items(matchers: applyV1Filters ? $1 : [], now: .now) }
            .eraseToAnyPublisher()
    }

    func contextPublisher(id: Status.Id, applyV1Filters: Bool) -> AnyPublisher<[CollectionSection], Error> {
        ValueObservation.tracking(
            ContextItemsInfo.request(StatusRecord.filter(StatusRecord.Columns.id == id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .combineLatest(activeFilterMatchersPublisher)
            .compactMap { $0?.items(matchers: applyV1Filters ? $1 : [], now: .now) }
            .eraseToAnyPublisher()
    }

    func accountListPublisher(
        id: AccountList.Id,
        configuration: CollectionItem.AccountConfiguration
    ) -> AnyPublisher<[CollectionSection], Error> {
        ValueObservation.tracking(
            AccountListItemsInfo.request(AccountList.filter(AccountList.Columns.id == id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map {
                $0?.accountAndRelationshipInfos.map {
                    CollectionItem.account(
                        .init(info: $0.accountInfo),
                        configuration,
                        $0.relationship,
                        $0.familiarFollowers.map { followingAccountInfo in .init(info: followingAccountInfo) },
                        $0.suggestion?.source
                    )
                }
            }
            .replaceNil(with: [])
            .map { [CollectionSection(items: $0)] }
            .eraseToAnyPublisher()
    }

    func listsPublisher() -> AnyPublisher<[Timeline], Error> {
        ValueObservation.tracking(TimelineRecord.filter(TimelineRecord.Columns.listId != nil)
                                    .order(TimelineRecord.Columns.listTitle.asc)
                                    .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .tryMap { $0.map(Timeline.init(record:)).compactMap { $0 } }
            .eraseToAnyPublisher()
    }

    func expiredFiltersPublisher() -> AnyPublisher<[Filter], Error> {
        ValueObservation.tracking { try Filter.filter(Filter.Columns.expiresAt < Date()).fetchAll($0) }
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func followedTagsPublisher() -> AnyPublisher<[FollowedTag], Error> {
        ValueObservation.tracking { try FollowedTag.fetchAll($0) }
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func profilePublisher(id: Account.Id) -> AnyPublisher<Profile, Error> {
        ValueObservation.tracking(ProfileInfo.request(AccountRecord.filter(AccountRecord.Columns.id == id)).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .compactMap { $0 }
            .map(Profile.init(info:))
            .eraseToAnyPublisher()
    }

    func relationshipPublisher(id: Account.Id) -> AnyPublisher<Relationship, Error> {
        ValueObservation.tracking(Relationship.filter(Relationship.Columns.id == id).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Given search results, return a publisher that augments those search results
    /// with account relationships and status visibility toggles.
    func publisher(results: Results, limit: Int?) -> AnyPublisher<[CollectionSection], Error> {
        let accountIds = results.accounts.map(\.id)
        let statusIds = results.statuses.map(\.id)

        return ValueObservation.tracking { db -> ([AccountAndRelationshipInfo], [StatusInfo]) in
            (
                try AccountAndRelationshipInfo
                    .request(AccountRecord.filter(accountIds.contains(AccountRecord.Columns.id)))
                    .fetchAll(db),
                try StatusInfo
                    .request(
                        StatusRecord.filter(statusIds.contains(StatusRecord.Columns.id)),
                        .search
                    )
                    .fetchAll(db)
            )
        }
        .publisher(in: databaseWriter)
        .map { accountAndRelationshipInfos, statusInfos in
            var accounts = accountAndRelationshipInfos.sorted {
                accountIds.firstIndex(of: $0.accountInfo.record.id) ?? 0
                    < accountIds.firstIndex(of: $1.accountInfo.record.id) ?? 0
            }
            .map { CollectionItem.account(
                .init(info: $0.accountInfo),
                .withoutNote,
                $0.relationship,
                $0.familiarFollowers.map { followingAccountInfo in .init(info: followingAccountInfo) },
                $0.suggestion?.source
            ) }

            if let limit = limit, accounts.count >= limit {
                accounts.append(.moreResults(.init(scope: .accounts)))
            }

            var statuses = statusInfos.sorted {
                statusIds.firstIndex(of: $0.record.id) ?? 0
                    < statusIds.firstIndex(of: $1.record.id) ?? 0
            }
            .map {
                CollectionItem.status(
                    .init(info: $0),
                    .init(
                        showContentToggled: $0.showContentToggled,
                        showAttachmentsToggled: $0.showAttachmentsToggled,
                        showFilteredToggled: $0.showFilteredToggled
                    ),
                    $0.reblogInfo?.relationship ?? $0.relationship)
            }

            if let limit = limit, statuses.count >= limit {
                statuses.append(.moreResults(.init(scope: .statuses)))
            }

            var hashtags = results.hashtags.map(CollectionItem.tag)

            if let limit = limit, hashtags.count >= limit {
                hashtags.append(.moreResults(.init(scope: .tags)))
            }

            return [.init(items: accounts, searchScope: .accounts),
                    .init(items: statuses, searchScope: .statuses),
                    .init(items: hashtags, searchScope: .tags)]
                .filter { !$0.items.isEmpty }
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    // TODO: (Vyr) we're probably not filtering these correctly for filters v1 clients
    func notificationsPublisher(
        excludeTypes: Set<MastodonNotification.NotificationType>
    ) -> AnyPublisher<[CollectionSection], Error> {
        ValueObservation.tracking(
            NotificationInfo.request(
                NotificationRecord.order(NotificationRecord.Columns.createdAt.desc)
                    .filter(!excludeTypes.map(\.rawValue).contains(NotificationRecord.Columns.type))).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map { [.init(items: $0.map {
                let configuration: CollectionItem.StatusConfiguration?

                if $0.record.type == .mention, let statusInfo = $0.statusInfo {
                    configuration = CollectionItem.StatusConfiguration(
                        showContentToggled: statusInfo.showContentToggled,
                        showAttachmentsToggled: statusInfo.showAttachmentsToggled,
                        showFilteredToggled: statusInfo.showFilteredToggled
                    )
                } else {
                    configuration = nil
                }

                let rules = $0.reportInfo?.rules ?? []

                return .notification(MastodonNotification(info: $0), rules, configuration)
            })] }
            .eraseToAnyPublisher()
    }

    func conversationsPublisher() -> AnyPublisher<[Conversation], Error> {
        ValueObservation.tracking(ConversationInfo.request(ConversationRecord.all()).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map {
                $0.sorted { $0.lastStatusInfo.record.createdAt > $1.lastStatusInfo.record.createdAt }
                    .map(Conversation.init(info:))
            }
            .eraseToAnyPublisher()
    }

    func instancePublisher() -> AnyPublisher<Instance, Error> {
        ValueObservation.tracking(
            InstanceInfo.request(InstanceRecord.all()).fetchOne)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .compactMap { $0 }
            .combineLatest(rulesPublisher())
            .map { Instance(info: $0, rules: $1) }
            .eraseToAnyPublisher()
    }

    func announcementCountPublisher() -> AnyPublisher<(total: Int, unread: Int), Error> {
        ValueObservation.tracking(Announcement.fetchCount)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .combineLatest(ValueObservation.tracking(Announcement.filter(Announcement.Columns.read == false).fetchCount)
                            .removeDuplicates()
                            .publisher(in: databaseWriter))
            .map { (total: $0, unread: $1) }
            .eraseToAnyPublisher()
    }

    func announcementsPublisher() -> AnyPublisher<[CollectionSection], Error> {
        ValueObservation.tracking(Announcement.order(Announcement.Columns.publishedAt).fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .map { [CollectionSection(items: $0.map(CollectionItem.announcement))] }
            .eraseToAnyPublisher()
    }

    func pickerEmojisPublisher() -> AnyPublisher<[Emoji], Error> {
        ValueObservation.tracking(
            Emoji.filter(Emoji.Columns.visibleInPicker == true)
                .order(Emoji.Columns.shortcode.asc)
                .fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func emojiUses(limit: Int) -> AnyPublisher<[EmojiUse], Error> {
        databaseWriter.readPublisher(value: EmojiUse.all().order(EmojiUse.Columns.count.desc).limit(limit).fetchAll)
            .eraseToAnyPublisher()
    }

    func rulesPublisher() -> AnyPublisher<[Rule], Error> {
        ValueObservation.tracking(Rule.fetchAll)
            .removeDuplicates()
            .publisher(in: databaseWriter)
            .eraseToAnyPublisher()
    }

    func lastReadId(timelineId: Timeline.Id) -> String? {
        try? databaseWriter.read {
            try String.fetchOne(
                $0,
                LastReadIdRecord.filter(LastReadIdRecord.Columns.timelineId == timelineId)
                    .select(LastReadIdRecord.Columns.id))
        }
    }

    /// Look up an account that might be in our database by URL.
    /// Returns up to one ID.
    func lookup(accountURL url: URL) -> AnyPublisher<Account.Id, Error> {
        databaseWriter
            .readPublisher(
                value: AccountRecord
                    .filter(AccountRecord.Columns.url == url.absoluteString)
                    .select(AccountRecord.Columns.id, as: Account.Id.self)
                    .fetchOne
            )
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Look up a status that might be in our database by URL, matching on the `uri` or `url` fields.
    /// Returns up to one ID.
    func lookup(statusURL url: URL) -> AnyPublisher<Status.Id, Error> {
        let urlString = url.absoluteString
        return databaseWriter
            .readPublisher(
                value: StatusRecord
                    .filter(StatusRecord.Columns.uri == urlString || StatusRecord.Columns.url == urlString)
                    .select(StatusRecord.Columns.id, as: Status.Id.self)
                    .fetchOne
            )
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Look up an object that has an URL and might be in our database.
    /// Returns up to one ID.
    func lookup(url: URL) -> AnyPublisher<URLLookupResult, Error> {
        let accountPublisher = lookup(accountURL: url).map { URLLookupResult.account($0) }
        let statusPublisher = lookup(statusURL: url).map { URLLookupResult.status($0) }
        return accountPublisher
            .merge(with: statusPublisher)
            .first()
            .eraseToAnyPublisher()
    }

    /// Handle not-found API errors by removing the relevant object.
    /// Use this as a handler for `Publisher.catch` when 404s are a possibility.
    /// Preserves the original error. 
    func catchNotFound<Output>(_ failure: Error) -> AnyPublisher<Output, Error> {
        let failurePublisher = Fail(outputType: Output.self, failure: failure)

        if let error = failure as? SpecialCaseError,
           case let .notFound(what) = error.specialCase {
            return delete(what)
                .andThen {
                    failurePublisher
                }
                .eraseToAnyPublisher()
        }

        return failurePublisher.eraseToAnyPublisher()
    }
}

public enum URLLookupResult {
    case account(_ id: Account.Id)
    case status(_ id: Status.Id)
}

private extension ContentDatabase {
    static let cleanAfterLastReadIdCount = 40
    static let ephemeralTimelines = NSCountedSet()

    static func fileURL(id: Identity.Id, appGroup: String) throws -> URL {
        try FileManager.default.databaseDirectoryURL(name: id.uuidString, appGroup: appGroup)
    }

    static func statusIdsToDeleteForPositionPreservingClean(db: Database) throws -> Set<Status.Id> {
        var statusIds = try Status.Id.fetchAll(
            db,
            TimelineStatusJoin.select(TimelineStatusJoin.Columns.statusId)
                .order(TimelineStatusJoin.Columns.statusId.desc))

        if let lastReadId = try Status.Id.fetchOne(
            db,
            LastReadIdRecord.filter(LastReadIdRecord.Columns.timelineId == Timeline.home.id)
                .select(LastReadIdRecord.Columns.id))
            ?? statusIds.first,
           let index = statusIds.firstIndex(of: lastReadId) {
            statusIds = Array(statusIds.prefix(index + Self.cleanAfterLastReadIdCount))
        }

        let quoteStatusIds = try Status.Id.fetchSet(
            db,
            StatusRecord.filter(statusIds.contains(StatusRecord.Columns.id)
                                    && StatusRecord.Columns.quoteId != nil)
                .select(StatusRecord.Columns.quoteId))

        let reblogStatusIds = try Status.Id.fetchSet(
            db,
            StatusRecord.filter(statusIds.contains(StatusRecord.Columns.id)
                                    && StatusRecord.Columns.reblogId != nil)
                .select(StatusRecord.Columns.reblogId))

        let statusIdsToKeep = Set(statusIds).union(quoteStatusIds).union(reblogStatusIds)
        let allStatusIds = try Status.Id.fetchSet(db, StatusRecord.select(StatusRecord.Columns.id))

        return  allStatusIds.subtracting(statusIdsToKeep)
    }

    static func accountIdsToDeleteForPositionPreservingClean(db: Database) throws -> Set<Account.Id> {
        var accountIdsToKeep = try Account.Id.fetchSet(db, StatusRecord.select(StatusRecord.Columns.accountId))
        accountIdsToKeep.formUnion(try Account.Id.fetchSet(
            db,
            AccountRecord.filter(accountIdsToKeep.contains(AccountRecord.Columns.id)
                                    && AccountRecord.Columns.movedId != nil)
                .select(AccountRecord.Columns.movedId)))
        let allAccountIds = try Account.Id.fetchSet(db, AccountRecord.select(AccountRecord.Columns.id))

        return allAccountIds.subtracting(accountIdsToKeep)
    }

    /// If an API call told us something wasn't found, delete it.
    private func delete(_ what: EntityNotFound) -> AnyPublisher<Never, Error> {
        switch what {
        case let .account(id):
            // The block() function actually deletes our record of the account.
            return block(id: id)
        case let .filter(id):
            return deleteFilter(id: id)
        case let .list(id):
            return deleteList(id: id)
        case let .status(id):
            return delete(id: id)
        default:
            #if DEBUG
            fatalError("Don't know how to handle \(String(describing: what))")
            #else
            return Empty().eraseToAnyPublisher()
            #endif
        }
    }
}
