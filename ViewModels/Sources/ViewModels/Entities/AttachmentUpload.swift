// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class AttachmentUploadViewModel: ObservableObject {
  public let id = Id()
  public let progress = Progress(totalUnitCount: 1)
  public let parentViewModel: ComposeStatusViewModel

  let data: Data
  let mimeType: String
  let description: String?
  var cancellable: AnyCancellable?

  init(data: Data, mimeType: String, description: String?, parentViewModel: ComposeStatusViewModel) {
    self.data = data
    self.mimeType = mimeType
    self.description = description
    self.parentViewModel = parentViewModel
  }
}

extension AttachmentUploadViewModel {
  public typealias Id = UUID

  public func upload() -> AnyPublisher<Attachment, Error> {
    parentViewModel.identityContext.service.uploadAttachment(
      data: data,
      mimeType: mimeType,
      description: description,
      progress: progress
    )
  }

  public func cancel() {
    cancellable?.cancel()
  }
}
