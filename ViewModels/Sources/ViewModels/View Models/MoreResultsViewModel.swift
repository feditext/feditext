// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import ServiceLayer

public final class MoreResultsViewModel: ObservableObject {
  private let moreResults: MoreResults

  init(moreResults: MoreResults) {
    self.moreResults = moreResults
  }
}

extension MoreResultsViewModel {
  public var scope: SearchScope { moreResults.scope }
}
