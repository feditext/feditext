// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import Mastodon
import ServiceLayer

public final class InstanceViewModel: ObservableObject {
  private let instanceService: InstanceService

  public init(instanceService: InstanceService) {
    self.instanceService = instanceService
  }
}

extension InstanceViewModel {
  public var instance: Instance { instanceService.instance }
}
