// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Mastodon

/// Things we can do to a list: update its title, replies policy, and exclusive flag.
public final class ListTimelineActionViewModel: ObservableObject {
  @Published public private(set) var list: List

  private let identityContext: IdentityContext

  public init(
    list: List,
    identityContext: IdentityContext
  ) {
    self.list = list
    self.identityContext = identityContext
  }

  public var editListViewModel: EditListViewModel {
    EditListViewModel(list: list, identityContext: identityContext)
  }
}
