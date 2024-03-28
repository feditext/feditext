// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import ServiceLayer

public enum CollectionItemEvent: ToastableEvent {
    case ignorableOutput
    /// Non-actionable error that we want to be displayed as a toast.
    case toast(AlertItem)
    /// The entity whose context we're looking at is gone, and we should navigate back.
    /// This can be a focused post in a thread, the account that owns some posts, the tag for a tag timeline, etc.
    case contextParentDeleted
    case refresh
    case navigation(Navigation)
    case reload(CollectionItem)
    case presentEmojiPicker(sourceViewTag: Int, selectionAction: (String) -> Void)
    case attachment(AttachmentViewModel, StatusViewModel)
    case compose(
        identity: Identity? = nil,
        inReplyTo: StatusViewModel? = nil,
        redraft: Status? = nil,
        edit: Status? = nil,
        wasContextParent: Bool = false,
        directMessageTo: AccountViewModel? = nil
    )
    case confirmDelete(StatusViewModel, redraft: Bool)
    case confirmUnfollow(AccountViewModel)
    case confirmHideReblogs(AccountViewModel)
    case confirmShowReblogs(AccountViewModel)
    case confirmMute(AccountViewModel)
    case confirmUnmute(AccountViewModel)
    case confirmBlock(AccountViewModel)
    case confirmUnblock(AccountViewModel)
    case confirmDomainBlock(AccountViewModel)
    case confirmDomainUnblock(AccountViewModel)
    case report(ReportViewModel)
    case share(URL)
    case accountListEdit(AccountViewModel, AccountListEdit)
    case presentHistory(StatusHistoryViewModel)
    case editNote(AccountViewModel)
}

public extension CollectionItemEvent {
    enum AccountListEdit {
        case acceptFollowRequest
        case rejectFollowRequest
        case removeFollowSuggestion
    }
}
