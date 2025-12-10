// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import MastodonAPI
import ServiceLayer

/// View model for editing a single existing list.
public final class EditListViewModel: ObservableObject {
  private let id: List.Id
  public let originalTitle: String
  @Published public var title: String
  @Published public var repliesPolicy: List.RepliesPolicy
  @Published public var exclusive: Bool
  @Published public private(set) var alertItem: AlertItem?

  private let identityContext: IdentityContext
  private var cancellables = Set<AnyCancellable>()

  public init(list: List, identityContext: IdentityContext) {
    self.id = list.id
    self.originalTitle = list.title
    self.title = list.title
    self.repliesPolicy = list.repliesPolicy ?? .list
    self.exclusive = list.exclusive ?? false
    self.identityContext = identityContext
  }

  /// Does this instance support replies policies?
  public var canUseRepliesPolicy: Bool {
    ListEndpoint.create(title: "", repliesPolicy: .unknown, exclusive: nil)
      .canCallWith(identityContext.apiCapabilities)
  }

  /// Does this instance support exclusive lists?
  public var canUseExclusive: Bool {
    ListEndpoint.create(title: "", repliesPolicy: nil, exclusive: true)
      .canCallWith(identityContext.apiCapabilities)
  }

  public func update() {
    identityContext.service
      .updateList(
        .init(
          id: id,
          title: title,
          repliesPolicy: canUseRepliesPolicy ? repliesPolicy : nil,
          exclusive: canUseExclusive ? exclusive : nil
        )
      )
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .sink { _ in }
      .store(in: &cancellables)
  }
}
