// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public protocol Endpoint {
    associatedtype ResultType: Decodable
    var APIVersion: String { get }
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

public extension Endpoint {
    var defaultContext: [String] {
        ["api", APIVersion]
    }

    var APIVersion: String { "v1" }

    var context: [String] {
        defaultContext
    }

    var pathComponents: [String] {
        context + pathComponentsInContext
    }

    var queryParameters: [URLQueryItem] { [] }

    var jsonBody: [String: Any]? { nil }

    var multipartFormData: [String: MultipartFormValue]? { nil }

    var headers: [String: String]? { nil }

    var requires: APICapabilityRequirements? { nil }

    var fallback: ResultType? { nil }

    var notFound: EntityNotFound? { nil }

    /// We only have to satisfy requirements if they exist.
    func canCallWith(_ apiCapabilities: APICapabilities) -> Bool {
        apiCapabilities.compatibilityMode != nil || requires?.satisfiedBy(apiCapabilities) ?? true
    }
}

internal extension Endpoint {
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
