// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public protocol Endpoint {
  associatedtype ResultType: Decodable
  var apiVersion: String { get }
  var context: [String] { get }
  var pathComponentsInContext: [String] { get }
  var method: HTTPMethod { get }
  var queryParameters: [URLQueryItem] { get }
  var jsonBody: [String: Any]? { get }
  var multipartFormData: [String: MultipartFormValue]? { get }
  var headers: [String: String]? { get }
  /// Does this API only exist on some servers?
  var requires: APICapabilityRequirements? { get }
  /// Is there a value we can return if the API doesn't exist?
  var fallback: ResultType? { get }
  /// If the object being requested is not found, what should we delete?
  var notFound: EntityNotFound? { get }
}

extension Endpoint {
  public var defaultContext: [String] {
    ["api", apiVersion]
  }

  public var apiVersion: String { "v1" }

  public var context: [String] {
    defaultContext
  }

  public var pathComponents: [String] {
    context + pathComponentsInContext
  }

  public var queryParameters: [URLQueryItem] { [] }

  public var jsonBody: [String: Any]? { nil }

  public var multipartFormData: [String: MultipartFormValue]? { nil }

  public var headers: [String: String]? { nil }

  public var requires: APICapabilityRequirements? { nil }

  public var fallback: ResultType? { nil }

  public var notFound: EntityNotFound? { nil }

  /// We only have to satisfy requirements if they exist.
  public func canCallWith(_ apiCapabilities: APICapabilities) -> Bool {
    apiCapabilities.compatibilityMode != nil || requires?.satisfiedBy(apiCapabilities) ?? true
  }
}

extension Endpoint {
  func queryParameters(_ limit: Int?, _ offset: Int?) -> [URLQueryItem] {
    var params = [URLQueryItem]()
    if let limit = limit {
      params.append(.init(name: "limit", value: .init(limit)))
    }
    if let offset = offset {
      params.append(.init(name: "offset", value: .init(offset)))
    }
    return params
  }
}
