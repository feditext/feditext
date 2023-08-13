// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// Retrieve a JRD doc.
public struct JRDTarget {
    /// Base URL of the Fedi server instance.
    public let instanceURL: URL
}

extension JRDTarget: Target {
    public var baseURL: URL { instanceURL }
    public var pathComponents: [String] { [".well-known", "nodeinfo"] }
    public var method: HTTP.HTTPMethod { .get }
    public var queryParameters: [URLQueryItem] { [] }
    public var jsonBody: [String: Any]? { nil }
    public var multipartFormData: [String: HTTP.MultipartFormValue]? { nil }
    public var headers: [String: String]? { ["Accept": "application/json"] }
}

extension JRDTarget: DecodableTarget {
    public typealias ResultType = JRD
}
