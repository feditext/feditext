// Copyright © 2023 Vyr Cossont. All rights reserved.

import AppUrls
import Combine
import Mastodon
import MastodonAPI

/// Things we can do to a tag: get the current follow state, and follow or unfollow it.
public final class TagTimelineActionViewModel: ObservableObject {
  @Published public private(set) var tag: Tag

  private let identityContext: IdentityContext
  private weak var collectionItemsViewModel: CollectionItemsViewModel?

  public init(
    name: Tag.Name,
    identityContext: IdentityContext,
    collectionItemsViewModel: CollectionItemsViewModel
  ) {
    // Create a stub Tag struct. The URL is a dummy and nothing should use it.
    self.tag = .init(
      name: name,
      url: .init(url: AppUrl.tagTimeline(name).url),
      history: nil,
      following: nil
    )
    self.identityContext = identityContext
    self.collectionItemsViewModel = collectionItemsViewModel

    if TagEndpoint.get(name: "").canCallWith(identityContext.apiCapabilities) {
      // Fetch the rest of the tag, including following status.
      getTag()
    }
  }

  private func getTag() {
    guard let collectionItemsViewModel = collectionItemsViewModel else { return }

    self.identityContext.service.getTag(name: tag.name)
      .assignErrorsToAlertItem(to: \.alertItem, on: collectionItemsViewModel)
      .assign(to: &$tag)
  }

  public func follow() {
    guard let collectionItemsViewModel = collectionItemsViewModel else { return }

    self.identityContext.service.followTag(name: tag.name)
      .assignErrorsToAlertItem(to: \.alertItem, on: collectionItemsViewModel)
      .assign(to: &$tag)
  }

  public func unfollow() {
    guard let collectionItemsViewModel = collectionItemsViewModel else { return }

    self.identityContext.service.unfollowTag(name: tag.name)
      .assignErrorsToAlertItem(to: \.alertItem, on: collectionItemsViewModel)
      .assign(to: &$tag)
  }
}
