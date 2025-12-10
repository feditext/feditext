// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Thrown when an API call fails to decode its result.
public struct AnnotatedDecodingError: Error, AnnotatedError, LocalizedError, Encodable {
  public let error: EncodableDecodingError?
  public let method: String
  public let url: URL
  public let requestLocation: DebugLocation

  public init(
    decodingError: DecodingError,
    method: String,
    url: URL,
    requestLocation: DebugLocation
  ) {
    self.error = .init(decodingError)
    self.method = method
    self.url = url
    self.requestLocation = requestLocation
  }

  public init?(
    decodingError: DecodingError,
    target: Target,
    requestLocation: DebugLocation
  ) {
    let request = target.urlRequest()
    guard let method = request.httpMethod, let url = request.url else { return nil }
    self.init(
      decodingError: decodingError,
      method: method,
      url: url,
      requestLocation: requestLocation
    )
  }

  public var errorDescription: String? {
    if let error = error {
      return "\(method) \(url.absoluteString)\n\n\(String(describing: error))"
    } else {
      return "\(method) \(url.absoluteString)\n\nunknown error reason"
    }
  }

  public var failQuietly: Bool { false }

  public enum EncodableDecodingError: Encodable {
    case dataCorrupted(context: EncodableContext)
    case keyNotFound(codingKey: String, context: EncodableContext)
    case typeMismatch(type: String, context: EncodableContext)
    case valueNotFound(type: String, context: EncodableContext)

    public init?(_ decodingError: DecodingError) {
      switch decodingError {
      case .typeMismatch(let type, let context):
        self = .typeMismatch(type: String(reflecting: type), context: .init(context))
      case .valueNotFound(let type, let context):
        self = .valueNotFound(type: String(reflecting: type), context: .init(context))
      case .keyNotFound(let codingKey, let context):
        self = .keyNotFound(codingKey: String(reflecting: codingKey), context: .init(context))
      case .dataCorrupted(let context):
        self = .dataCorrupted(context: .init(context))
      @unknown default:
        return nil
      }
    }
  }

  public struct EncodableContext: Encodable {
    public var codingPath: [String]
    public var debugDescription: String
    public var underlyingError: EncodableError?

    public init(_ context: DecodingError.Context) {
      self.codingPath = context.codingPath.map(String.init(reflecting:))
      self.debugDescription = context.debugDescription
      self.underlyingError = context.underlyingError.map(EncodableError.init)
    }
  }

  public struct EncodableError: Encodable {
    public var type: String
    public var localizedDescription: String

    public init(_ error: Error) {
      self.type = String(describing: Swift.type(of: error))
      self.localizedDescription = error.localizedDescription
    }
  }
}
