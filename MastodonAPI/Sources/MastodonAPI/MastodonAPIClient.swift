// Copyright © 2020 Metabolist. All rights reserved.

import AppMetadata
import Combine
import CombineInterop
import Foundation
import HTTP
import Mastodon
import os

/// Mastodon API client.
/// Handles authentication, fallbacks for unavailable APIs, API-level errors, and paged result sets.
public struct MastodonAPIClient: Sendable {
    private let httpClient: HTTPClient
    public let instanceURL: URL
    public let accessToken: String?
    public let apiCapabilities: APICapabilities

    public init(
        session: URLSession,
        instanceURL: URL,
        apiCapabilities: APICapabilities,
        accessToken: String?,
        allowUnencryptedHTTP: Bool = false
    ) throws {
        guard instanceURL.scheme == "https" || (instanceURL.scheme == "http" && allowUnencryptedHTTP) else {
            throw MastodonAPIClientError.protocolNotSupported(instanceURL.scheme)
        }

        self.httpClient = .init(session: session)
        self.instanceURL = instanceURL
        self.apiCapabilities = apiCapabilities
        self.accessToken = accessToken
    }

    /// Performance signposter for API calls.
    private static let signposter = OSSignposter(subsystem: AppMetadata.bundleIDBase, category: .pointsOfInterest)

    /// Signpost name for this class.
    private static let signpostName: StaticString = "MastodonAPIClient"

    // swiftlint:disable force_try
    /// Used for retrieving paging IDs from Link headers.
    private static let linkDataDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    // swiftlint:enable force_try

    private func requestCommon<E: Endpoint>(
        _ endpoint: E,
        progress: Progress? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) async throws -> (decoded: E.ResultType, response: HTTPURLResponse?) {
        let requestLocation = DebugLocation(file: file, line: line, function: function)
        let target = MastodonAPITarget(
            baseURL: instanceURL,
            endpoint: endpoint,
            accessToken: accessToken
        )

        let signpostID = Self.signposter.makeSignpostID()
        var signpostURL = target.baseURL
        for pathComponent in target.pathComponents {
            signpostURL.appendPathComponent(pathComponent)
        }
        let signpostInterval = Self.signposter.beginInterval(
            Self.signpostName,
            id: signpostID,
            "\(endpoint.method.rawValue, privacy: .public) \(signpostURL.absoluteString, privacy: .public)"
        )
        defer {
            Self.signposter.endInterval(Self.signpostName, signpostInterval)
        }

        guard endpoint.canCallWith(apiCapabilities) else {
            if let fallback = endpoint.fallback {
                return (fallback, nil)
            }
            throw APINotAvailableError(
                target: target,
                requestLocation: requestLocation,
                apiCapabilities: apiCapabilities
            )
        }

        do {
            do {
                return try await httpClient.request(
                    target,
                    progress: progress,
                    file: file,
                    line: line,
                    function: function
                )
            } catch let httpError as HTTPError {
                if httpError.reason == .invalidStatusCode,
                   let data = httpError.data,
                   let response = httpError.httpResponse,
                   let apiError = try? target.decoder.decode(APIError.self, from: data) {
                    throw AnnotatedAPIError(
                        apiError: apiError,
                        target: target,
                        response: response,
                        requestLocation: requestLocation,
                        apiCapabilities: apiCapabilities
                    ) ?? apiError
                }
                throw httpError
            }
        } catch {
            if apiCapabilities.compatibilityMode == .fallbackOnErrors,
               let fallback = endpoint.fallback {
                return (fallback, nil)
            }
            throw error
        }
    }

    /// Request a single object.
    public func request<E: Endpoint>(
        _ endpoint: E,
        progress: Progress? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) async throws -> E.ResultType {
        try await requestCommon(
            endpoint,
            progress: progress,
            file: file,
            line: line,
            function: function
        ).decoded
    }

    /// Request something where the complete list of results is paged using `Link` headers.
    public func pagedRequest<E: Endpoint>(
        _ endpoint: E,
        maxId: String? = nil,
        minId: String? = nil,
        sinceId: String? = nil,
        limit: Int? = nil,
        progress: Progress? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) async throws -> PagedResult<E.ResultType> {
        let (decoded, response) = try await requestCommon(
            endpoint,
            progress: progress,
            file: file,
            line: line,
            function: function
        )

        var maxId: String?
        var minId: String?
        var sinceId: String?
        if let response = response,
           let links = response.value(forHTTPHeaderField: "Link") {
            let queryItems = Self.linkDataDetector.matches(
                in: links,
                range: .init(links.startIndex..<links.endIndex, in: links))
                .compactMap { match -> [URLQueryItem]? in
                    guard let url = match.url else { return nil }

                    return URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems
                }
                .reduce([], +)

            maxId = queryItems.first { $0.name == "max_id" }?.value
            minId = queryItems.first { $0.name == "min_id" }?.value
            sinceId = queryItems.first { $0.name == "since_id" }?.value
        }

        return PagedResult(
            result: decoded,
            info: .init(maxId: maxId, minId: minId, sinceId: sinceId)
        )
    }
}

/// Combine wrappers for async methods.
public extension MastodonAPIClient {
    func request<E: Endpoint>(
        _ endpoint: E,
        progress: Progress? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) -> AnyPublisher<E.ResultType, Error> {
        Future {
            try await request(
                endpoint,
                progress: progress,
                file: file,
                line: line,
                function: function
            )
        }
        .eraseToAnyPublisher()
    }

    func pagedRequest<E: Endpoint>(
        _ endpoint: E,
        maxId: String? = nil,
        minId: String? = nil,
        sinceId: String? = nil,
        limit: Int? = nil,
        progress: Progress? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) -> AnyPublisher<PagedResult<E.ResultType>, Error> {
        Future {
            try await pagedRequest(
                endpoint,
                maxId: maxId,
                minId: minId,
                sinceId: sinceId,
                limit: limit,
                progress: progress,
                file: file,
                line: line,
                function: function
            )
        }
        .eraseToAnyPublisher()
    }
}

/// Errors that can be thrown when creating a Mastodon API client.
public enum MastodonAPIClientError: Error {
    /// We only support making Mastodon API calls over HTTPS except for testing purposes.
    case protocolNotSupported(_ scheme: String?)
}
