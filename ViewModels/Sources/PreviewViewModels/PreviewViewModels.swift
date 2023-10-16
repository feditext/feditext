// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import MastodonAPIStubs
import MockKeychain
import Secrets
import ServiceLayer
import ServiceLayerMocks
import ViewModels

// swiftlint:disable force_try

let identityId = Identity.Id()

let db: IdentityDatabase = {
    let db = try! IdentityDatabase(inMemory: true, appGroup: "", keychain: MockKeychain.self)
    let secrets = Secrets(identityId: identityId, keychain: MockKeychain.self)

    try! secrets.setInstanceURL(.previewInstanceURL)
    try! secrets.setAccessToken(UUID().uuidString)

    _ = db.createIdentity(id: identityId, url: .previewInstanceURL, authenticated: true, pending: false)
            .receive(on: ImmediateScheduler.shared)
            .sink { _ in } receiveValue: { _ in }

    _ = db.updateInstance(.preview, id: identityId)
        .receive(on: ImmediateScheduler.shared)
        .sink { _ in } receiveValue: { _ in }

    _ = db.updateAccount(.preview, id: identityId)
        .receive(on: ImmediateScheduler.shared)
        .sink { _ in } receiveValue: { _ in }

    return db
}()

let environment = AppEnvironment.mock(fixtureDatabase: db)
let decoder = MastodonDecoder()

extension NodeInfo {
    static let preview = Self(
        openRegistrations: false,
        software: .init(
            name: "mastodon",
            version: "4.2.0"
        )
    )
}

extension APICapabilities {
    static let preview = Self(nodeInfo: .preview)
}

extension MastodonAPIClient {
    static let preview = try! MastodonAPIClient(
        session: URLSession(configuration: .stubbing),
        instanceURL: .previewInstanceURL,
        apiCapabilities: .preview,
        accessToken: nil
    )
}

extension ContentDatabase {
    static let preview = try! ContentDatabase(
        id: identityId,
        useHomeTimelineLastReadId: false,
        inMemory: true,
        appGroup: "group.test.example",
        keychain: MockKeychain.self)
}

public extension AppEnvironment {
    static let preview = environment
}

public extension URL {
    static let previewInstanceURL = URL(string: "https://mastodon.social")!
}

public extension Account {
    static let preview = try! decoder.decode(Account.self, from: StubData.account)
}

public extension Instance {
    static let preview = try! decoder.decode(Instance.self, from: StubData.instance)
}

public extension RootViewModel {
    static let preview = try! RootViewModel(environment: environment,
                                            registerForRemoteNotifications: { Empty().eraseToAnyPublisher() })
}

public extension IdentityContext {
    static let preview = RootViewModel.preview.navigationViewModel!.identityContext
}

public extension ReportViewModel {
    static let preview = ReportViewModel(
        accountService: AccountService(
            account: .preview,
            environment: environment,
            mastodonAPIClient: .preview,
            contentDatabase: .preview),
        identityContext: .preview)
}

public extension MuteViewModel {
    static let preview = MuteViewModel(
        accountService: AccountService(
            account: .preview,
            environment: environment,
            mastodonAPIClient: .preview,
            contentDatabase: .preview),
        identityContext: .preview)
}

public extension DomainBlocksViewModel {
    static let preview = DomainBlocksViewModel(service: .init(mastodonAPIClient: .preview))
}

public extension StatusHistoryViewModel {
    static let preview = StatusHistoryViewModel(
        identityContext: .preview,
        navigationService: .init(
            environment: .preview,
            mastodonAPIClient: .preview,
            contentDatabase: .preview
        ),
        eventsSubject: .init(),
        history: [
            .init(
                createdAt: .init(timeIntervalSince1970: 1676058147),
                account: .preview,
                content: .init(raw: "<p>first verse</p>"),
                sensitive: false,
                spoilerText: "",
                mediaAttachments: [],
                emojis: [],
                poll: nil
            ),
            .init(
                createdAt: .init(timeIntervalSince1970: 1676058194),
                account: .preview,
                content: .init(raw: "<p>first verse</p>\n<p>second verse</p>"),
                sensitive: false,
                spoilerText: "",
                mediaAttachments: [],
                emojis: [],
                poll: nil
            )
        ]
    )
}

public extension InstanceViewModel {
    static let preview = InstanceViewModel(
        instanceService: .init(
            instance: .preview,
            mastodonAPIClient: .preview
        )
    )
}

public extension NavigationViewModel {
    static let preview = NavigationViewModel(
        identityContext: .preview,
        environment: .preview
    )
}

public extension APICapabilitiesViewModel {
    static let preview = Self(apiCapabilities: .preview)
}


// swiftlint:enable force_try
