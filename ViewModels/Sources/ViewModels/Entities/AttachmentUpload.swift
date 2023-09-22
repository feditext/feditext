// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class AttachmentUploadViewModel: ObservableObject {
    public let id = Id()
    public let progress = Progress(totalUnitCount: 1)
    public let parentViewModel: ComposeStatusViewModel

    let inputStream: InputStream
    let mimeType: String
    let description: String?
    var cancellable: AnyCancellable?

    init(inputStream: InputStream, mimeType: String, description: String?, parentViewModel: ComposeStatusViewModel) {
        self.inputStream = inputStream
        self.mimeType = mimeType
        self.description = description
        self.parentViewModel = parentViewModel
    }
}

public extension AttachmentUploadViewModel {
    typealias Id = UUID

    func upload() -> AnyPublisher<Attachment, Error> {
        parentViewModel.identityContext.service.uploadAttachment(
            inputStream: inputStream,
            mimeType: mimeType,
            description: description,
            progress: progress
        )
    }

    func cancel() {
        cancellable?.cancel()
    }
}
