// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct LoadMore: Hashable {
  public let timeline: Timeline
  public let afterStatusId: Status.Id
  public let beforeStatusId: Status.Id
}

extension LoadMore {
  public enum Direction {
    case up
    case down
  }
}
