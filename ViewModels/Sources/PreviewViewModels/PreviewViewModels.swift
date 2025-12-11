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
    .sink { _ in
    } receiveValue: { _ in
    }

  _ = db.updateInstance(.preview, id: identityId)
    .receive(on: ImmediateScheduler.shared)
    .sink { _ in
    } receiveValue: { _ in
    }

  _ = db.updateAccount(.preview, id: identityId)
    .receive(on: ImmediateScheduler.shared)
    .sink { _ in
    } receiveValue: { _ in
    }

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
    keychain: MockKeychain.self
  )
}

extension AppEnvironment {
  public static let preview = environment
}

extension URL {
  public static let previewInstanceURL = URL(string: "https://mastodon.social")!
}

extension Account {
  public static let preview = try! decoder.decode(Account.self, from: StubData.account)
}

extension Instance {
  public static let preview = try! decoder.decode(Instance.self, from: StubData.instance)
}

extension RootViewModel {
  public static let preview = try! RootViewModel(
    environment: environment,
    registerForRemoteNotifications: { Empty().eraseToAnyPublisher() }
  )
}

extension IdentityContext {
  public static let preview = RootViewModel.preview.navigationViewModel!.identityContext
}

extension ReportViewModel {
  public static let preview = ReportViewModel(
    accountService: AccountService(
      account: .preview,
      environment: environment,
      mastodonAPIClient: .preview,
      contentDatabase: .preview
    ),
    identityContext: .preview
  )
}

extension MuteViewModel {
  public static let preview = MuteViewModel(
    accountService: AccountService(
      account: .preview,
      environment: environment,
      mastodonAPIClient: .preview,
      contentDatabase: .preview
    ),
    identityContext: .preview
  )
}

extension DomainBlocksViewModel {
  public static let preview = DomainBlocksViewModel(service: .init(mastodonAPIClient: .preview))
}

extension StatusHistoryViewModel {
  public static let preview = StatusHistoryViewModel(
    identityContext: .preview,
    navigationService: .init(
      environment: .preview,
      mastodonAPIClient: .preview,
      contentDatabase: .preview
    ),
    eventsSubject: .init(),
    history: [
      .init(
        createdAt: .init(timeIntervalSince1970: 1_676_058_147),
        account: .preview,
        content: .init(raw: "<p>first verse</p>"),
        sensitive: false,
        spoilerText: "",
        mediaAttachments: [],
        emojis: [],
        poll: nil
      ),
      .init(
        createdAt: .init(timeIntervalSince1970: 1_676_058_194),
        account: .preview,
        content: .init(raw: "<p>first verse</p>\n<p>second verse</p>"),
        sensitive: false,
        spoilerText: "",
        mediaAttachments: [],
        emojis: [],
        poll: nil
      ),
    ],
    language: nil
  )
}

extension InstanceViewModel {
  public static let preview = InstanceViewModel(
    instanceService: .init(
      instance: .preview,
      mastodonAPIClient: .preview
    )
  )
}

extension NavigationViewModel {
  public static let preview = NavigationViewModel(
    identityContext: .preview,
    environment: .preview
  )
}

extension APICapabilitiesViewModel {
  public static let preview = Self(apiCapabilities: .preview)
}

// swiftlint:enable force_try
