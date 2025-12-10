// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Medium-level HTTP error thrown when we get an unexpected response code or a non-HTTP response.
public struct HTTPError: Error, AnnotatedError, LocalizedError, Encodable {
  /// Used internally, should not be encoded.
  public let data: Data?
  /// Used internally, should not be encoded.
  public let httpResponse: HTTPURLResponse?

  public let reason: Reason
  public let method: String?
  public let url: URL?
  public let statusCode: Int?
  public let requestLocation: DebugLocation

  enum CodingKeys: CodingKey {
    case reason
    case method
    case url
    case statusCode
    case requestLocation
  }

  public init(
    data: Data?,
    httpResponse: HTTPURLResponse?,
    reason: Reason,
    method: String?,
    url: URL?,
    statusCode: Int?,
    requestLocation: DebugLocation
  ) {
    self.data = data
    self.httpResponse = httpResponse
    self.reason = reason
    self.method = method
    self.url = url
    self.statusCode = statusCode
    self.requestLocation = requestLocation
  }

  public init(
    target: Target,
    requestLocation: DebugLocation
  ) {
    let request = target.urlRequest()
    self.init(
      data: nil,
      httpResponse: nil,
      reason: .nonHTTPURLResponse,
      method: request.httpMethod,
      url: request.url,
      statusCode: nil,
      requestLocation: requestLocation
    )
  }

  public init(
    target: Target,
    data: Data,
    httpResponse: HTTPURLResponse,
    requestLocation: DebugLocation
  ) {
    let request = target.urlRequest()
    self.init(
      data: data,
      httpResponse: httpResponse,
      reason: .invalidStatusCode,
      method: request.httpMethod,
      url: request.url,
      statusCode: httpResponse.statusCode,
      requestLocation: requestLocation
    )
  }

  public var errorDescription: String? {
    let message: String
    switch self.reason {
    case .nonHTTPURLResponse:
      message = NSLocalizedString("http-error.non-http-response", comment: "")
    case .invalidStatusCode:
      message = String.localizedStringWithFormat(
        NSLocalizedString("http-error.status-code-%ld", comment: ""),
        statusCode ?? -1
      )
    }

    if let method = method, let url = url {
      return "\(method) \(url.absoluteString)\n\n\(message)"
    }

    return message
  }

  public var failQuietly: Bool {
    switch reason {
    case .nonHTTPURLResponse:
      return false
    case .invalidStatusCode:
      return method.flatMap { HTTPMethod(rawValue: $0) }?.safe ?? false
    }
  }

  public enum Reason: String, Encodable {
    case nonHTTPURLResponse
    case invalidStatusCode
  }
}
