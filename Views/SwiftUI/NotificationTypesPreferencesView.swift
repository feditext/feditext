// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import SwiftUI
import ViewModels

/// Controls which notifications are received and from whom.
/// See also: `NotificationPreferencesView`
struct NotificationTypesPreferencesView: View {
  @StateObject var viewModel: NotificationTypesPreferencesViewModel

  var body: some View {
    Form {
      Section {
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.follow) {
          Label(
            MastodonNotification.NotificationType.follow.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.follow.systemImageName)
        }
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.favourite) {
          Label(
            MastodonNotification.NotificationType.favourite.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.favourite.systemImageName)
        }
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.reblog) {
          Label(
            MastodonNotification.NotificationType.reblog.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.reblog.systemImageName)
        }
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.mention) {
          Label(
            MastodonNotification.NotificationType.mention.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.mention.systemImageName)
        }
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.followRequest) {
          Label(
            MastodonNotification.NotificationType.followRequest.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.followRequest.systemImageName)
        }
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.poll) {
          Label(
            MastodonNotification.NotificationType.poll.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.poll.systemImageName)
        }
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.status) {
          Label(
            MastodonNotification.NotificationType.status.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.status.systemImageName)
        }
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.update) {
          Label(
            MastodonNotification.NotificationType.update.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.update.systemImageName)
        }
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.adminSignup) {
          Label(
            MastodonNotification.NotificationType.adminSignup.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.adminSignup.systemImageName)
        }
        Toggle(isOn: $viewModel.pushSubscriptionAlerts.adminReport) {
          Label(
            MastodonNotification.NotificationType.adminReport.localizedStringKey,
            systemImage: MastodonNotification.NotificationType.adminReport.systemImageName)
        }
      }

      Section {
        Picker(
          "preferences.notification-policy.picker-title",
          selection: $viewModel.pushSubscriptionPolicy
        ) {
          ForEach(PushSubscription.Policy.allCasesExceptUnknown) { policy in
            Text(policy.localizedStringKey).tag(policy)
          }
        }
        .pickerStyle(.inline)
      }
    }
    .navigationTitle("preferences.notifications")
    .alertItem($viewModel.alertItem)
  }
}

#if DEBUG
  import PreviewViewModels

  struct NotificationTypesPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
      NotificationTypesPreferencesView(viewModel: .init(identityContext: .preview))
    }
  }
#endif
