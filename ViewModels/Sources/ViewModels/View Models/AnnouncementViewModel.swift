// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class AnnouncementViewModel: ObservableObject {
  public let identityContext: IdentityContext

  private let announcementService: AnnouncementService
  private let eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>

  init(
    announcementService: AnnouncementService,
    identityContext: IdentityContext,
    eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>
  ) {
    self.announcementService = announcementService
    self.identityContext = identityContext
    self.eventsSubject = eventsSubject
  }
}

extension AnnouncementViewModel {
  public var announcement: Announcement { announcementService.announcement }
}

extension AnnouncementViewModel {
  public func urlSelected(_ url: URL) {
    eventsSubject.send(
      announcementService.navigationService.lookup(url: url, identityId: identityContext.identity.id)
        .map { .navigation($0) }
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher())
  }

  public func dismissIfUnread() {
    guard !announcement.read else { return }

    eventsSubject.send(
      announcementService.dismiss()
        .map { _ in .ignorableOutput }
        .eraseToAnyPublisher())
  }

  public func reload() {
    eventsSubject.send(
      Just(.reload(.announcement(announcementService.announcement)))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher())
  }

  public func addReaction(name: String) {
    eventsSubject.send(
      announcementService.addReaction(name: name)
        .map { _ in .ignorableOutput }
        .eraseToAnyPublisher())
  }

  public func removeReaction(name: String) {
    eventsSubject.send(
      announcementService.removeReaction(name: name)
        .map { _ in .ignorableOutput }
        .eraseToAnyPublisher())
  }

  public func presentEmojiPicker(sourceViewTag: Int) {
    eventsSubject.send(
      Just(
        .presentEmojiPicker(
          sourceViewTag: sourceViewTag,
          selectionAction: { [weak self] in self?.addReaction(name: $0) })
      )
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher())
  }
}
