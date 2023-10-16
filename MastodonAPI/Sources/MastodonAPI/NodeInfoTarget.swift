// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// Retrieve a NodeInfo doc.
public struct NodeInfoTarget {
    /// URL of the NodeInfo doc, from the JRD used to find it.
    public let url: URL
}

extension NodeInfoTarget: Target {
    public var baseURL: URL { url }
    public var pathComponents: [String] { [] }
    public var method: HTTP.HTTPMethod { .get }
    public var queryParameters: [URLQueryItem] { [] }
    public var jsonBody: [String: Any]? { nil }
    public var multipartFormData: [String: HTTP.MultipartFormValue]? { nil }
    public var headers: [String: String]? { ["Accept": "application/json"] }
}

extension NodeInfoTarget: DecodableTarget {
    public typealias ResultType = NodeInfo
    public var decoder: JSONDecoder { .init() }
}
