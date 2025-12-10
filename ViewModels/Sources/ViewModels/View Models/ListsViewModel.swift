// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import MastodonAPI
import ServiceLayer

public final class ListsViewModel: ObservableObject {
  @Published public private(set) var lists = [List]()
  @Published public private(set) var creatingList = false
  @Published public var alertItem: AlertItem?
  public let identityContext: IdentityContext

  private var cancellables = Set<AnyCancellable>()

  public init(identityContext: IdentityContext) {
    self.identityContext = identityContext

    identityContext.service.listsPublisher()
      .map {
        $0.compactMap {
          guard case .list(let list) = $0 else { return nil }

          return list
        }
      }
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .assign(to: &$lists)
  }
}

extension ListsViewModel {
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

  public func refreshLists() {
    identityContext.service.refreshLists()
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .sink { _ in }
      .store(in: &cancellables)
  }

  public func createList(title: String, repliesPolicy: List.RepliesPolicy, exclusive: Bool) {
    identityContext.service
      .createList(
        title: title,
        repliesPolicy: canUseRepliesPolicy ? repliesPolicy : nil,
        exclusive: canUseExclusive ? exclusive : nil
      )
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .handleEvents(
        receiveSubscription: { [weak self] _ in self?.creatingList = true },
        receiveCompletion: { [weak self] _ in self?.creatingList = false }
      )
      .sink { _ in }
      .store(in: &cancellables)
  }

  public func update(list: List) {
    identityContext.service.updateList(list)
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .handleEvents(
        receiveSubscription: { [weak self] _ in self?.creatingList = true },
        receiveCompletion: { [weak self] _ in self?.creatingList = false }
      )
      .sink { _ in }
      .store(in: &cancellables)
  }

  public func delete(list: List) {
    identityContext.service.deleteList(id: list.id)
      .assignErrorsToAlertItem(to: \.alertItem, on: self)
      .sink { _ in }
      .store(in: &cancellables)
  }
}
