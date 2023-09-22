// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import Combine
import CoreGraphics
import Foundation
import ImageIO
import os
#if canImport(UIKit)
import UIKit
#endif
import UniformTypeIdentifiers

enum MediaProcessingError: Error {
    case invalidMimeType
    case fileURLNotFound
    case imageNotFound
    case unsupportedType
    case unableToCreateImageSource
    case unableToDownsample
    case unableToCreateImageDataDestination
}

/// Possible errors when loading alt text for a media item.
/// Mostly for debugging. as they're all recoverable by just not providing any alt text.
enum AltTextError: String, Error {
    case noUrl
    case dataProvider
    case imageSource
    case primaryImageProperties
    case iptcMetadata
    case iptcDescription
}

public enum MediaProcessingService {}

public extension MediaProcessingService {
    static func dataAndMimeType(itemProvider: NSItemProvider) -> AnyPublisher<(data: InputStream, mimeType: String), Error> {
        let registeredTypes = itemProvider.registeredTypeIdentifiers.compactMap(UTType.init)

        let mimeType: String
        let dataPublisher: AnyPublisher<InputStream, Error>

        if let type = registeredTypes.first(where: {
            guard let mimeType = $0.preferredMIMEType else { return false }

            return uploadableMimeTypes.contains(mimeType)
        }), let preferredMIMEType = type.preferredMIMEType {
            mimeType = preferredMIMEType
            dataPublisher = fileRepresentationDataPublisher(itemProvider: itemProvider, type: type)
        } else if registeredTypes == [UTType.image], let pngMIMEType = UTType.png.preferredMIMEType { // screenshot
            mimeType = pngMIMEType
            dataPublisher = UIImagePNGDataPublisher(itemProvider: itemProvider)
        } else {
            return Fail(error: MediaProcessingError.invalidMimeType).eraseToAnyPublisher()
        }

        return dataPublisher.map { (data: $0, mimeType: mimeType) }.eraseToAnyPublisher()
    }

    /// Get alt text for an image, audio, or video from its comment metadata.
    /// If there's an error, or it doesn't have a comment, or it's not a type we understand, return `nil`.
    static func description(itemProvider: NSItemProvider) -> AnyPublisher<String?, Never> {
        let registeredTypes = itemProvider.registeredTypeIdentifiers.compactMap(UTType.init)
        if registeredTypes.contains(where: { $0.conforms(to: .image) }) {
            return Self.loadFileRepresentation(itemProvider, for: .image)
                .tryMap(Self.imageDescription(url:))
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        } else if registeredTypes.contains(where: { $0.conforms(to: .audiovisualContent) }) {
            return Self.loadFileRepresentation(itemProvider, for: .audiovisualContent)
                .flatMap { url in
                    Self.withTempCopy(url) { tempUrl in
                        Future {
                            try await Self.avDescription(url: tempUrl)
                        }
                    }
                }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        } else {
            return Just(nil)
                .eraseToAnyPublisher()
        }
    }
}

private extension MediaProcessingService {
    // TODO: (Vyr) replace this with the supported MIME types list from /api/vX/instance .configuration
    static let uploadableMimeTypes = Set(
        [UTType.png,
         UTType.jpeg,
         UTType.gif,
         UTType.webP,
         UTType.mpeg4Movie,
         UTType.quickTimeMovie,
         UTType.mp3,
         UTType.wav]
            .compactMap(\.preferredMIMEType))
    static let imageSourceOptions =  [kCGImageSourceShouldCache: false] as CFDictionary
    static let thumbnailOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: 1280
    ] as [CFString: Any] as CFDictionary

    static func fileRepresentationDataPublisher(itemProvider: NSItemProvider,
                                                type: UTType) -> AnyPublisher<InputStream, Error> {
        Future<InputStream, Error> { promise in
            itemProvider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                if let error = error {
                    promise(.failure(error))
                } else if let url = url {
                    promise(Result {
                        if type.conforms(to: .image) && type != .gif {
                            return try imageData(url: url, type: type)
                        } else {
                            guard let stream = InputStream(url: url) else { throw MediaProcessingError.fileURLNotFound }
                            // The temporary file will be removed upon return. Opening a stream gives us a file descriptor, which allows
                            // to hold onto the file after it has been deleted.
                            stream.open()
                            return stream
                        }
                    })
                } else {
                    promise(.failure(MediaProcessingError.fileURLNotFound))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    static func UIImagePNGDataPublisher(itemProvider: NSItemProvider) -> AnyPublisher<InputStream, Error> {
        #if canImport(UIKit)
        return Future<InputStream, Error> { promise in
            itemProvider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                if let error = error {
                    promise(.failure(error))
                } else if let image = item as? UIImage, let data = image.pngData() {
                    promise(Result {
                        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                            .appendingPathComponent(UUID().uuidString)

                        try data.write(to: url)

                        return try imageData(url: url, type: .png)
                    })
                } else {
                    promise(.failure(MediaProcessingError.imageNotFound))
                }
            }
        }
        .eraseToAnyPublisher()
        #else
        return Fail<Data, Error>(error: MediaProcessingError.invalidMimeType).eraseToAnyPublisher()
        #endif
    }

    static func imageData(url: URL, type: UTType) throws -> InputStream {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, Self.imageSourceOptions) else {
            throw MediaProcessingError.unableToCreateImageSource
        }

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            throw MediaProcessingError.unableToDownsample
        }

        let data = NSMutableData()

        guard let imageDestination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil) else {
            throw MediaProcessingError.unableToCreateImageDataDestination
        }

        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)

        return InputStream(data: data as Data)
    }

    /// Convert this `NSItemProvider` callback into a Combine `Future`.
    /// Would be async using `withCheckedThrowingContinuation` but `NSItemProvider` isn't `Sendable`,
    /// so there's no easy way to get it into an async context, and thus no point.
    static func loadFileRepresentation(
        _ itemProvider: NSItemProvider,
        for utType: UTType
    ) -> Future<URL, Error> {
        Future { promise in
            itemProvider.loadFileRepresentation(forTypeIdentifier: utType.identifier) { url, error in
                if let error = error {
                    promise(.failure(error))
                } else if let url = url {
                    promise(.success(url))
                } else {
                    promise(.failure(AltTextError.noUrl))
                }
            }
        }
    }

    /// Use Core Graphics to read IPTC image description.
    /// Core Graphics seems to coerce other metadata formats to IPTC properties automatically.
    static func imageDescription(url: URL) throws -> String? {
        guard let dataProvider = CGDataProvider(url: url as CFURL) else {
            throw AltTextError.dataProvider
        }

        guard let imageSource = CGImageSourceCreateWithDataProvider(dataProvider, nil) else {
            throw AltTextError.imageSource
        }

        let primaryImageIndex = CGImageSourceGetPrimaryImageIndex(imageSource)

        guard let imageProperties: NSDictionary = CGImageSourceCopyPropertiesAtIndex(
            imageSource,
            primaryImageIndex,
            nil
        ) else {
            throw AltTextError.primaryImageProperties
        }

        guard let iptcMetadata = imageProperties[kCGImagePropertyIPTCDictionary] as? NSDictionary else {
            throw AltTextError.iptcMetadata
        }

        guard let iptcDescription = iptcMetadata[kCGImagePropertyIPTCCaptionAbstract] as? String else {
            throw AltTextError.iptcDescription
        }

        return iptcDescription
    }

    /// Use AVFoundation to read the accessibility description or regular description for a piece of media.
    static func avDescription(url: URL) async throws -> String? {
        let asset = AVAsset(url: url)
        let commonMetadata = try await asset.load(.commonMetadata)

        if let accessibilityDescription = try await AVMetadataItem.metadataItems(
            from: commonMetadata,
            filteredByIdentifier: .commonIdentifierAccessibilityDescription
        ).first?.load(.stringValue) {
            return accessibilityDescription
        }

        if let description = try await AVMetadataItem.metadataItems(
            from: commonMetadata,
            filteredByIdentifier: .commonIdentifierDescription
        ).first?.load(.stringValue) {
            return description
        }

        return nil
    }

    /// Run `operation` on a temporary copy of the contents of file URL `url`.
    static func withTempCopy<P>(
        _ url: URL,
        operation: @Sendable @escaping (URL) -> P
    ) -> AnyPublisher<P.Output, Error> where P: Publisher {
        // Not using `FileManager.url(for:in:appropriateFor:create:)` because that gets us a URL in the same
        // temporary directory as the item provider's, which is deleted when the item provider closure returns.
        // Preserve the file extension because that's apparently what AVFoundation uses to learn a file's type.
        let tempUrl: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(url.pathExtension)
        do {
            try FileManager.default.copyItem(at: url, to: tempUrl)
        } catch {
            return Fail<P.Output, Error>(error: error)
                .eraseToAnyPublisher()
        }

        return operation(tempUrl)
            .tryMap {
                try FileManager.default.removeItem(at: tempUrl)
                return $0
            }
            .mapError {
                try? FileManager.default.removeItem(at: tempUrl)
                return $0
            }
            .eraseToAnyPublisher()
    }
}
