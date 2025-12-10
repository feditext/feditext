// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import MastodonAPI
import ServiceLayer

public final class IdentityContext: ObservableObject {
  @Published private(set) public var identity: Identity
  @Published private(set) public var authenticatedOtherIdentities = [Identity]()
  @Published public var appPreferences: AppPreferences
  let service: IdentityService

  init(
    identity: Identity,
    publisher: AnyPublisher<Identity, Never>,
    service: IdentityService,
    environment: AppEnvironment
  ) {
    self.identity = identity
    self.service = service
    appPreferences = AppPreferences(environment: environment)

    DispatchQueue.main.async {
      publisher.dropFirst().assign(to: &self.$identity)
      service.otherAuthenticatedIdentitiesPublisher()
        .replaceError(with: [])
        .assign(to: &self.$authenticatedOtherIdentities)
    }
  }

  // These are stored outside normal app preferences because they have to be available everywhere an API client is.

  public var apiCapabilities: APICapabilities { service.apiCapabilities }

  public func getAPICompatibilityMode() -> APICompatibilityMode? {
    service.getAPICompatibilityMode()
  }

  /// Does not update existing API clients.
  public func setAPICompatibilityMode(_ newValue: APICompatibilityMode?) throws {
    try service.setAPICompatibilityMode(newValue)
  }
}
