// Copyright © 2021 Metabolist. All rights reserved.

import Mastodon
import SwiftUI
import ViewModels

/// Controls how notifications are displayed and which sounds they make.
/// See also: `NotificationTypesPreferencesView`
struct NotificationPreferencesView: View {
  @StateObject var viewModel: PreferencesViewModel
  @StateObject var identityContext: IdentityContext

  init(viewModel: PreferencesViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
    _identityContext = StateObject(wrappedValue: viewModel.identityContext)
  }

  var body: some View {
    Form {
      Section {
        Toggle(
          "preferences.notifications.include-pictures",
          isOn: $identityContext.appPreferences.notificationPictures
        )
        Toggle(
          "preferences.notifications.include-account-name",
          isOn: $identityContext.appPreferences.notificationAccountName
        )
        Toggle(
          "preferences.notifications.grouping",
          isOn: $identityContext.appPreferences.notificationGrouping
        )
      }
      Section(header: Text("preferences.notifications.sounds")) {
        ForEach(MastodonNotification.NotificationType.allCasesExceptUnknown) { type in
          Toggle(
            isOn: .init {
              viewModel.identityContext.appPreferences.notificationSounds.contains(type)
            } set: {
              if $0 {
                viewModel.identityContext.appPreferences.notificationSounds.insert(type)
              } else {
                viewModel.identityContext.appPreferences.notificationSounds.remove(type)
              }
            }
          ) {
            Label(type.localizedStringKey, systemImage: type.systemImageName)
          }
        }
      }
    }
    .navigationTitle("preferences.notifications.display-and-sounds")
  }
}

#if DEBUG
  import PreviewViewModels

  struct NotificationPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
      NotificationPreferencesView(viewModel: .init(identityContext: .preview))
    }
  }
#endif
