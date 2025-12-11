// Copyright © 2020 Metabolist. All rights reserved.

import DB
import Foundation
import HTTP
import Keychain
import MockKeychain
import ServiceLayer
import Stubbing

extension AppEnvironment {
  public static func mock(
    session: URLSession = URLSession(configuration: .stubbing),
    webAuthSessionType: WebAuthSession.Type = SuccessfulMockWebAuthSession.self,
    keychain: Keychain.Type = MockKeychain.self,
    userDefaults: UserDefaults = MockUserDefaults(),
    userNotificationClient: UserNotificationClient = .mock,
    uuid: @escaping () -> UUID = UUID.init,
    inMemoryContent: Bool = true,
    fixtureDatabase: IdentityDatabase? = nil
  ) -> Self {
    AppEnvironment(
      session: session,
      webAuthSessionType: webAuthSessionType,
      keychain: keychain,
      userDefaults: userDefaults,
      userNotificationClient: userNotificationClient,
      reduceMotion: { false },
      autoplayVideos: { true },
      uuid: uuid,
      inMemoryContent: inMemoryContent,
      fixtureDatabase: fixtureDatabase
    )
  }
}
