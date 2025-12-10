// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NotificationTypesPreferencesViewModel: ObservableObject {
  @Published public var pushSubscriptionAlerts: PushSubscription.Alerts
  @Published public var pushSubscriptionPolicy: PushSubscription.Policy
  @Published public var alertItem: AlertItem?
  public let identityContext: IdentityContext

  private var cancellables = Set<AnyCancellable>()

  public init(identityContext: IdentityContext) {
    self.identityContext = identityContext
    pushSubscriptionAlerts = identityContext.identity.pushSubscriptionAlerts
    pushSubscriptionPolicy = identityContext.identity.pushSubscriptionPolicy

    identityContext.$identity
      .map(\.pushSubscriptionAlerts)
      .dropFirst()
      .removeDuplicates()
      .assign(to: &$pushSubscriptionAlerts)
    $pushSubscriptionAlerts
      .dropFirst()
      .removeDuplicates()
      .sink { [weak self] in
        guard let self = self else { return }
        self.update(alerts: $0, policy: self.pushSubscriptionPolicy)
      }
      .store(in: &cancellables)

    identityContext.$identity
      .map(\.pushSubscriptionPolicy)
      .dropFirst()
      .removeDuplicates()
      .assign(to: &$pushSubscriptionPolicy)
    $pushSubscriptionPolicy
      .dropFirst()
      .removeDuplicates()
      .sink { [weak self] in
        guard let self = self else { return }
        self.update(alerts: self.pushSubscriptionAlerts, policy: $0)
      }
      .store(in: &cancellables)
  }
}

extension NotificationTypesPreferencesViewModel {
  fileprivate func update(alerts: PushSubscription.Alerts, policy: PushSubscription.Policy) {
    guard
      alerts != identityContext.identity.pushSubscriptionAlerts
        || policy != identityContext.identity.pushSubscriptionPolicy
    else { return }

    identityContext.service.updatePushSubscription(alerts: alerts, policy: policy)
      .sink { [weak self] in
        guard let self = self, case .failure(let error) = $0 else { return }

        self.alertItem = AlertItem(error: error)
        self.pushSubscriptionAlerts = self.identityContext.identity.pushSubscriptionAlerts
        self.pushSubscriptionPolicy = self.identityContext.identity.pushSubscriptionPolicy
      } receiveValue: { _ in
      }
      .store(in: &cancellables)
  }
}
