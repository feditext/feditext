// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Thrown when an API call fails and returns a low-level error.
public struct AnnotatedURLError: Error, AnnotatedError, LocalizedError, Encodable {
  public let code: Int
  public let name: Name?
  public let backgroundTaskCancelledReason: BackgroundTaskCancelledReason?
  public let networkUnavailableReason: NetworkUnavailableReason?
  public let method: String
  public let url: URL
  public let requestLocation: DebugLocation

  public init(
    urlError: URLError,
    method: String,
    url: URL,
    requestLocation: DebugLocation
  ) {
    self.code = urlError.code.rawValue
    self.name = .init(urlError.code)
    self.backgroundTaskCancelledReason = urlError.backgroundTaskCancelledReason
      .flatMap(BackgroundTaskCancelledReason.init)
    self.networkUnavailableReason = urlError.networkUnavailableReason
      .flatMap(NetworkUnavailableReason.init)
    self.method = method
    self.url = url
    self.requestLocation = requestLocation
  }

  public init?(
    urlError: URLError,
    target: Target,
    requestLocation: DebugLocation
  ) {
    let request = target.urlRequest()
    guard let method = request.httpMethod, let url = request.url else { return nil }
    self.init(
      urlError: urlError,
      method: method,
      url: url,
      requestLocation: requestLocation
    )
  }

  public var errorDescription: String? {
    if let name = name {
      return "\(method) \(url.absoluteString)\n\n\(name.rawValue)"
    } else {
      return "\(method) \(url.absoluteString)\n\nunknown error code: \(code)"
    }
  }

  public var failQuietly: Bool {
    switch name {
    case .cancelled, .timedOut:
      return HTTPMethod(rawValue: method)?.safe ?? false
    default:
      return false
    }
  }

  public enum Name: String, Encodable {
    case unknown
    case cancelled
    case badURL
    case timedOut
    case unsupportedURL
    case cannotFindHost
    case cannotConnectToHost
    case networkConnectionLost
    case dnsLookupFailed
    case httpTooManyRedirects
    case resourceUnavailable
    case notConnectedToInternet
    case redirectToNonExistentLocation
    case badServerResponse
    case userCancelledAuthentication
    case userAuthenticationRequired
    case zeroByteResource
    case cannotDecodeRawData
    case cannotDecodeContentData
    case cannotParseResponse
    case appTransportSecurityRequiresSecureConnection
    case fileDoesNotExist
    case fileIsDirectory
    case noPermissionsToReadFile
    case dataLengthExceedsMaximum
    case secureConnectionFailed
    case serverCertificateHasBadDate
    case serverCertificateUntrusted
    case serverCertificateHasUnknownRoot
    case serverCertificateNotYetValid
    case clientCertificateRejected
    case clientCertificateRequired
    case cannotLoadFromNetwork
    case cannotCreateFile
    case cannotOpenFile
    case cannotCloseFile
    case cannotWriteToFile
    case cannotRemoveFile
    case cannotMoveFile
    case downloadDecodingFailedMidStream
    case downloadDecodingFailedToComplete
    case internationalRoamingOff
    case callIsActive
    case dataNotAllowed
    case requestBodyStreamExhausted
    case backgroundSessionRequiresSharedContainer
    case backgroundSessionInUseByAnotherProcess
    case backgroundSessionWasDisconnected

    public init?(_ code: URLError.Code) {
      switch code {
      case .unknown:
        self = .unknown
      case .cancelled:
        self = .cancelled
      case .badURL:
        self = .badURL
      case .timedOut:
        self = .timedOut
      case .unsupportedURL:
        self = .unsupportedURL
      case .cannotFindHost:
        self = .cannotFindHost
      case .cannotConnectToHost:
        self = .cannotConnectToHost
      case .networkConnectionLost:
        self = .networkConnectionLost
      case .dnsLookupFailed:
        self = .dnsLookupFailed
      case .httpTooManyRedirects:
        self = .httpTooManyRedirects
      case .resourceUnavailable:
        self = .resourceUnavailable
      case .notConnectedToInternet:
        self = .notConnectedToInternet
      case .redirectToNonExistentLocation:
        self = .redirectToNonExistentLocation
      case .badServerResponse:
        self = .badServerResponse
      case .userCancelledAuthentication:
        self = .userCancelledAuthentication
      case .userAuthenticationRequired:
        self = .userAuthenticationRequired
      case .zeroByteResource:
        self = .zeroByteResource
      case .cannotDecodeRawData:
        self = .cannotDecodeRawData
      case .cannotDecodeContentData:
        self = .cannotDecodeContentData
      case .cannotParseResponse:
        self = .cannotParseResponse
      case .appTransportSecurityRequiresSecureConnection:
        self = .appTransportSecurityRequiresSecureConnection
      case .fileDoesNotExist:
        self = .fileDoesNotExist
      case .fileIsDirectory:
        self = .fileIsDirectory
      case .noPermissionsToReadFile:
        self = .noPermissionsToReadFile
      case .dataLengthExceedsMaximum:
        self = .dataLengthExceedsMaximum
      case .secureConnectionFailed:
        self = .secureConnectionFailed
      case .serverCertificateHasBadDate:
        self = .serverCertificateHasBadDate
      case .serverCertificateUntrusted:
        self = .serverCertificateUntrusted
      case .serverCertificateHasUnknownRoot:
        self = .serverCertificateHasUnknownRoot
      case .serverCertificateNotYetValid:
        self = .serverCertificateNotYetValid
      case .clientCertificateRejected:
        self = .clientCertificateRejected
      case .clientCertificateRequired:
        self = .clientCertificateRequired
      case .cannotLoadFromNetwork:
        self = .cannotLoadFromNetwork
      case .cannotCreateFile:
        self = .cannotCreateFile
      case .cannotOpenFile:
        self = .cannotOpenFile
      case .cannotCloseFile:
        self = .cannotCloseFile
      case .cannotWriteToFile:
        self = .cannotWriteToFile
      case .cannotRemoveFile:
        self = .cannotRemoveFile
      case .cannotMoveFile:
        self = .cannotMoveFile
      case .downloadDecodingFailedMidStream:
        self = .downloadDecodingFailedMidStream
      case .downloadDecodingFailedToComplete:
        self = .downloadDecodingFailedToComplete
      case .internationalRoamingOff:
        self = .internationalRoamingOff
      case .callIsActive:
        self = .callIsActive
      case .dataNotAllowed:
        self = .dataNotAllowed
      case .requestBodyStreamExhausted:
        self = .requestBodyStreamExhausted
      case .backgroundSessionRequiresSharedContainer:
        self = .backgroundSessionRequiresSharedContainer
      case .backgroundSessionInUseByAnotherProcess:
        self = .backgroundSessionInUseByAnotherProcess
      case .backgroundSessionWasDisconnected:
        self = .backgroundSessionWasDisconnected
      default:
        return nil
      }
    }
  }

  public enum BackgroundTaskCancelledReason: String, Encodable {
    case userForceQuitApplication
    case backgroundUpdatesDisabled
    case insufficientSystemResources

    public init?(_ reason: URLError.BackgroundTaskCancelledReason) {
      switch reason {
      case .userForceQuitApplication:
        self = .userForceQuitApplication
      case .backgroundUpdatesDisabled:
        self = .backgroundUpdatesDisabled
      case .insufficientSystemResources:
        self = .insufficientSystemResources
      @unknown default:
        return nil
      }
    }
  }

  public enum NetworkUnavailableReason: String, Encodable {
    case cellular
    case constrained
    case expensive

    public init?(_ reason: URLError.NetworkUnavailableReason) {
      switch reason {
      case .cellular:
        self = .cellular
      case .expensive:
        self = .expensive
      case .constrained:
        self = .constrained
      @unknown default:
        return nil
      }
    }
  }
}
