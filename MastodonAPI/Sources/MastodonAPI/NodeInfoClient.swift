// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Foundation
import HTTP
import Mastodon

/// Client for retrieving NodeInfo for an instance.
public final class NodeInfoClient: HTTPClient {
    private let instanceURL: URL
    private let allowUnencryptedHTTP: Bool

    public required init(session: URLSession, instanceURL: URL, allowUnencryptedHTTP: Bool = false) throws {
        guard instanceURL.scheme == "https" || (instanceURL.scheme == "http" && allowUnencryptedHTTP) else {
            throw JRDError.protocolNotSupported(instanceURL.scheme)
        }

        self.instanceURL = instanceURL
        self.allowUnencryptedHTTP = allowUnencryptedHTTP
        super.init(session: session, decoder: .init())
    }

    /// Retrieve a NodeInfo doc from the well-known location.
    public func nodeInfo() -> AnyPublisher<NodeInfo, Error> {
        request(JRDTarget(instanceURL: instanceURL))
            .tryMap(newestNodeInfoURL)
            .flatMap { url in self.request(NodeInfoTarget(url: url)) }
            .eraseToAnyPublisher()
    }

    /// Get URL for newest schema version available.
    func newestNodeInfoURL(_ jrd: JRD) throws -> URL {
        let url = (jrd.links ?? [])
            .compactMap { link -> (Version, URL)? in
                if let version = Version(rawValue: link.rel),
                   let href = link.href {
                    return (version, href)
                } else {
                    return nil
                }
            }
            .sorted { $0.0 < $1.0 }
            .last
            .map { $0.1 }

        guard let url = url else {
            throw JRDError.noSupportedNodeInfoVersionsInJrd
        }

        guard url.scheme == "https" || (url.scheme == "http" && allowUnencryptedHTTP) else {
            throw JRDError.protocolNotSupported(url.scheme)
        }

        return url
    }

    /// Known NodeInfo versions and their JRD relation URLs.
    ///
    /// - See: https://github.com/jhass/nodeinfo/blob/main/PROTOCOL.md#discovery
    enum Version: String, Comparable {
        case v_1_0 = "http://nodeinfo.diaspora.software/ns/schema/1.0"
        case v_1_1 = "http://nodeinfo.diaspora.software/ns/schema/1.1"
        case v_2_0 = "http://nodeinfo.diaspora.software/ns/schema/2.0"
        case v_2_1 = "http://nodeinfo.diaspora.software/ns/schema/2.1"

        /// - Invariant: assumes relation URLs are comparable lexically so that newer versions sort higher.
        public static func < (lhs: Version, rhs: Version) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Errors related to discovering a NodeInfo document using a JRD.
    public enum JRDError: Error {
        /// We only support retrieving NodeInfo over HTTPS except for testing purposes.
        case protocolNotSupported(_ scheme: String?)
        /// This might happen if everyone upgraded to a future NodeInfo version and stopped serving old ones.
        case noSupportedNodeInfoVersionsInJrd
    }
}
