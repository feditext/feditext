// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol AttachmentsRenderingViewModel {
  var attachmentViewModels: [AttachmentViewModel] { get }
  var shouldShowAttachments: Bool { get }
  var shouldShowHideAttachmentsButton: Bool { get }
  var sensitive: Bool { get }
  var canRemoveAttachments: Bool { get }
  var language: String? { get }
  func attachmentSelected(viewModel: AttachmentViewModel)
  func removeAttachment(viewModel: AttachmentViewModel)
  func toggleShowAttachments()
}

extension AttachmentsRenderingViewModel {
  public var shouldShowAttachments: Bool { true }
  public var shouldShowHideAttachmentsButton: Bool { false }
  public var sensitive: Bool { false }
  public var canRemoveAttachments: Bool { false }
  public func removeAttachment(viewModel: AttachmentViewModel) {}
  public func toggleShowAttachments() {}
}
