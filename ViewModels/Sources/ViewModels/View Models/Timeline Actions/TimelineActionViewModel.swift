// Copyright © 2023 Vyr Cossont. All rights reserved.

import ServiceLayer

/// Encapsulates actions we can do that are related to a timeline
/// and need to show UI for in a collection view.
/// UI is set up mostly in `TableViewController.setupTimelineActionBarButtonItem`.
public enum TimelineActionViewModel {
  case context(ContextTimelineActionViewModel)
  case tag(TagTimelineActionViewModel)
  case list(ListTimelineActionViewModel)
  case displayFilter(DisplayFilterTimelineActionViewModel)
  case conversations(ConversationsTimelineActionViewModel)

  static func from(
    timeline: Timeline,
    identityContext: IdentityContext,
    collectionService: CollectionService,
    collectionItemsViewModel: CollectionItemsViewModel
  ) -> Self? {
    switch timeline {
    case .tag(let name):
      return .tag(
        TagTimelineActionViewModel(
          name: name,
          identityContext: identityContext,
          collectionItemsViewModel: collectionItemsViewModel
        )
      )
    case .list(let list):
      return .list(
        ListTimelineActionViewModel(
          list: list,
          identityContext: identityContext
        )
      )
    case .home, .local, .federated:
      guard let timelineService = collectionService as? TimelineService else {
        assert(collectionService is TimelineService)
        return nil
      }
      return .displayFilter(
        DisplayFilterTimelineActionViewModel(timelineService)
      )
    default:
      return nil
    }
  }
}
