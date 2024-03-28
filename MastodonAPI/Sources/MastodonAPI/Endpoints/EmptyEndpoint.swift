// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum EmptyEndpoint {
    case oauthRevoke(token: String, clientId: String, clientSecret: String)
    case addAccountsToList(id: List.Id, accountIds: Set<Account.Id>)
    case removeAccountsFromList(id: List.Id, accountIds: Set<Account.Id>)
    case deleteList(id: List.Id)
    case deleteFilter(id: Filter.Id)
    /// https://docs.joinmastodon.org/methods/domain_blocks/#block
    case blockDomain(String)
    /// https://docs.joinmastodon.org/methods/domain_blocks/#unblock
    case unblockDomain(String)
    case dismissAnnouncement(id: Announcement.Id)
    case addAnnouncementReaction(id: Announcement.Id, name: String)
    case removeAnnouncementReaction(id: Announcement.Id, name: String)
    case removeFollowSuggestion(id: Account.Id)
    /// https://docs.joinmastodon.org/methods/conversations/#delete
    case removeConversation(id: Conversation.Id)
}

extension EmptyEndpoint: Endpoint {
    public typealias ResultType = [String: String]

    public var context: [String] {
        switch self {
        case .oauthRevoke:
            return ["oauth"]
        case .addAccountsToList, .removeAccountsFromList, .deleteList:
            return defaultContext + ["lists"]
        case .deleteFilter:
            return defaultContext + ["filters"]
        case .blockDomain, .unblockDomain:
            return defaultContext + ["domain_blocks"]
        case .dismissAnnouncement, .addAnnouncementReaction, .removeAnnouncementReaction:
            return defaultContext + ["announcements"]
        case .removeFollowSuggestion:
            return defaultContext + ["suggestions"]
        case .removeConversation:
            return defaultContext + ["conversations"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .oauthRevoke:
            return ["revoke"]
        case let .addAccountsToList(id, _), let .removeAccountsFromList(id, _):
            return [id, "accounts"]
        case let .deleteList(id), let .deleteFilter(id):
            return [id]
        case .blockDomain, .unblockDomain:
            return []
        case let .dismissAnnouncement(id):
            return [id, "dismiss"]
        case let .addAnnouncementReaction(id, name), let .removeAnnouncementReaction(id, name):
            return [id, "reactions", name]
        case let .removeFollowSuggestion(id):
            return [id]
        case let .removeConversation(id):
            return [id]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .addAccountsToList, .oauthRevoke, .blockDomain, .dismissAnnouncement:
            return .post
        case .addAnnouncementReaction:
            return .put
        case .removeAccountsFromList,
                .deleteList,
                .deleteFilter,
                .unblockDomain,
                .removeAnnouncementReaction,
                .removeFollowSuggestion,
                .removeConversation:
            return .delete
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .oauthRevoke(token, clientId, clientSecret):
            return ["token": token, "client_id": clientId, "client_secret": clientSecret]
        case let .addAccountsToList(_, accountIds), let .removeAccountsFromList(_, accountIds):
            return ["account_ids": Array(accountIds)]
        case let .blockDomain(domain), let .unblockDomain(domain):
            return ["domain": domain]
        case .deleteList,
                .deleteFilter,
                .dismissAnnouncement,
                .addAnnouncementReaction,
                .removeAnnouncementReaction,
                .removeFollowSuggestion,
                .removeConversation:
            return nil
        }
    }

    public var requires: APICapabilityRequirements? {
        switch self {
        case .dismissAnnouncement, .addAnnouncementReaction, .removeAnnouncementReaction:
            return AnnouncementsEndpoint.announcements.requires
        case .blockDomain, .unblockDomain:
            return StringsEndpoint.domainBlocks.requires
        case .removeFollowSuggestion:
            return SuggestionsEndpoint.suggestions().requires
        case .addAccountsToList, .removeAccountsFromList, .deleteList:
            return ListsEndpoint.lists.requires
        case .removeConversation:
            return ConversationsEndpoint.conversations.requires
        default:
            return nil
        }
    }

    public var notFound: EntityNotFound? {
        switch self {
        case .oauthRevoke,
                .blockDomain,
                .unblockDomain:
            return nil

        case .addAccountsToList(id: let id, _),
                .removeAccountsFromList(id: let id, _),
                .deleteList(id: let id):
            return .list(id)

        case .deleteFilter(id: let id):
            return .filter(id)

        case .dismissAnnouncement(id: let id),
                .addAnnouncementReaction(id: let id, _),
                .removeAnnouncementReaction(id: let id, _):
            return .announcement(id)

        case .removeFollowSuggestion(id: let id):
            // Note: Mastodon docs say this succeeds even if the account ID is invalid,
            // so this is for other implementations.
            return .account(id)

        case .removeConversation(id: let id):
            return .conversation(id)
        }
    }
}
