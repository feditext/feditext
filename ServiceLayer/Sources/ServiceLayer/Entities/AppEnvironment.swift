// Copyright © 2020 Metabolist. All rights reserved.

import DB
import Foundation
import HTTP
import Keychain
import Mastodon
import UserNotifications

public struct AppEnvironment {
    let session: URLSession
    let webAuthSessionType: WebAuthSession.Type
    let keychain: Keychain.Type
    let userDefaults: UserDefaults
    let userNotificationClient: UserNotificationClient
    let reduceMotion: () -> Bool
    let autoplayVideos: () -> Bool
    let uuid: () -> UUID
    let inMemoryContent: Bool
    let fixtureDatabase: IdentityDatabase?

    public init(session: URLSession,
                webAuthSessionType: WebAuthSession.Type,
                keychain: Keychain.Type,
                userDefaults: UserDefaults,
                userNotificationClient: UserNotificationClient,
                reduceMotion: @escaping () -> Bool,
                autoplayVideos: @escaping () -> Bool,
                uuid: @escaping () -> UUID,
                inMemoryContent: Bool,
                fixtureDatabase: IdentityDatabase?) {
        self.session = session
        self.webAuthSessionType = webAuthSessionType
        self.keychain = keychain
        self.userDefaults = userDefaults
        self.userNotificationClient = userNotificationClient
        self.reduceMotion = reduceMotion
        self.autoplayVideos = autoplayVideos
        self.uuid = uuid
        self.inMemoryContent = inMemoryContent
        self.fixtureDatabase = fixtureDatabase
    }
}

public extension AppEnvironment {
    /// Makes it possible to change the bundle ID of the app and all of its extensions from `Identify.xcconfig`.
    static var bundleIDBase: String {
        // swiftlint:disable:next force_cast
        Bundle.main.infoDictionary!["Feditext bundle ID base"] as! String
    }

    static var appGroup: String {
        "group.\(bundleIDBase)"
    }

    static func live(userNotificationCenter: UNUserNotificationCenter,
                     reduceMotion: @escaping () -> Bool,
                     autoplayVideos: @escaping () -> Bool) -> Self {
        Self(
            session: URLSession.shared,
            webAuthSessionType: LiveWebAuthSession.self,
            keychain: LiveKeychain.self,
            userDefaults: UserDefaults(suiteName: appGroup)!,
            userNotificationClient: .live(userNotificationCenter),
            reduceMotion: reduceMotion,
            autoplayVideos: autoplayVideos,
            uuid: UUID.init,
            inMemoryContent: false,
            fixtureDatabase: nil)
    }
}
