// Copyright © 2023 Vyr Cossont. All rights reserved.

import ServiceLayer

/// Encapsulates actions we can do that are related to a timeline
/// and need to show UI for in a collection view.
public enum TimelineActionViewModel {
    case tag(TagTimelineActionViewModel)

    static func from(timeline: Timeline, identityContext: IdentityContext) -> Self? {
        switch timeline {
        case let .tag(name):
            return .tag(TagTimelineActionViewModel(name: name, identityContext: identityContext))
        default:
            return nil
        }
    }
}
