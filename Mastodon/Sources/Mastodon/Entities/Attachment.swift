// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Attachment: Codable {
  public enum AttachmentType: String, Codable, Equatable, Unknowable {
    case image, video, gifv, audio, unknown

    public static var unknownCase: Self { .unknown }
  }

  // swiftlint:disable nesting
  public struct Meta: Codable, Hashable {
    public struct Info: Codable, Hashable {
      public let width: Int?
      public let height: Int?
      public let size: String?
      public let aspect: Double?
      public let frameRate: String?
      public let duration: Double?
      public let bitrate: Int?
    }

    public struct Focus: Codable, Hashable {
      public var x: Double?
      public var y: Double?
    }

    public let original: Info?
    public let small: Info?
    public let focus: Focus?
  }
  // swiftlint:enable nesting

  public let id: Id
  public let type: AttachmentType
  /// May be `nil` if the attachment hasn't been processed yet.
  /// - SeeAlso: <https://docs.joinmastodon.org/entities/MediaAttachment/#url>
  public let url: UnicodeURL?
  public let remoteUrl: UnicodeURL?
  public let previewUrl: UnicodeURL?
  public let meta: Meta?
  public let description: String?
  public let blurhash: String?
}

extension Attachment {
  public typealias Id = String

  public var aspectRatio: Double? {
    if let info = meta?.original,
      let width = info.width,
      let height = info.height,
      width != 0,
      height != 0
    {
      let aspectRatio = Double(width) / Double(height)

      return aspectRatio.isNaN ? nil : aspectRatio
    }

    return nil
  }
}

extension Attachment: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension Attachment.Meta.Focus {
  public static let `default` = Self(x: 0, y: 0)
}
