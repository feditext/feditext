// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import HTTP
import Mastodon

public final class MastodonAPIClient: HTTPClient {
    public let instanceURL: URL
    public var accessToken: String?
    public let apiCapabilities: APICapabilities

    public required init(
        session: URLSession,
        instanceURL: URL,
        apiCapabilities: APICapabilities,
        allowUnencryptedHTTP: Bool = false
    ) throws {
        guard instanceURL.scheme == "https" || (instanceURL.scheme == "http" && allowUnencryptedHTTP) else {
            throw MastodonAPIClientError.protocolNotSupported(instanceURL.scheme)
        }

        self.instanceURL = instanceURL
        self.apiCapabilities = apiCapabilities
        super.init(session: session, decoder: MastodonDecoder())
    }

    public override func dataTaskPublisher<T: DecodableTarget>(
        _ target: T,
        progress: Progress? = nil,
        requestLocation: DebugLocation
    ) -> AnyPublisher<(data: Data, response: HTTPURLResponse), Error> {
        let apiCapabilities = apiCapabilities
        return super.dataTaskPublisher(target, progress: progress, requestLocation: requestLocation)
            .mapError { [weak self] error -> Error in
                if let httpError = error as? HTTPError,
                   httpError.reason == .invalidStatusCode,
                   let data = httpError.data,
                   let response = httpError.httpResponse,
                   let apiError = try? self?.decoder.decode(APIError.self, from: data) {
                    return AnnotatedAPIError(
                        apiError: apiError,
                        target: target,
                        response: response,
                        requestLocation: requestLocation,
                        apiCapabilities: apiCapabilities
                    ) ?? apiError
                }

                return error
            }
            .eraseToAnyPublisher()
    }
}

extension MastodonAPIClient {
    public func request<E: Endpoint>(
        _ endpoint: E,
        progress: Progress? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) -> AnyPublisher<E.ResultType, Error> {
        let requestLocation = DebugLocation(file: file, line: line, function: function)
        let target = target(endpoint: endpoint)

        guard endpoint.canCallWith(apiCapabilities) else {
            if let fallback = endpoint.fallback {
                return Just(fallback)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } else {
                return Fail(
                    outputType: E.ResultType.self,
                    failure: APINotAvailableError(
                        target: target,
                        requestLocation: requestLocation,
                        apiCapabilities: apiCapabilities
                    )
                )
                .eraseToAnyPublisher()
            }
        }

        let compatibilityMode = apiCapabilities.compatibilityMode
        return dataTaskPublisher(target, progress: progress, requestLocation: requestLocation)
            .map(\.data)
            .decode(type: E.ResultType.self, decoder: decoder)
            .mapError { error in
                if let decodingError = error as? DecodingError,
                   let annotatedDecodingError = AnnotatedDecodingError(
                    decodingError: decodingError,
                    target: target,
                    requestLocation: requestLocation
                   ) {
                    return annotatedDecodingError as Error
                }
                return error
            }
            .tryCatch { error in
                if compatibilityMode == .fallbackOnErrors, let fallback = endpoint.fallback {
                    return Just(fallback).setFailureType(to: Error.self)
                }
                throw error
            }
            .eraseToAnyPublisher()
    }

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
    ) -> AnyPublisher<PagedResult<E.ResultType>, Error> {
        let requestLocation = DebugLocation(file: file, line: line, function: function)
        let pagedTarget = target(endpoint: Paged(endpoint, maxId: maxId, minId: minId, sinceId: sinceId, limit: limit))

        guard endpoint.canCallWith(apiCapabilities) else {
            if let fallback = endpoint.fallback {
                return Just(
                    PagedResult(
                        result: fallback,
                        info: .init(maxId: nil, minId: nil, sinceId: nil)
                    )
                )
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            } else {
                return Fail(
                    outputType: PagedResult<E.ResultType>.self,
                    failure: APINotAvailableError(
                        target: pagedTarget,
                        requestLocation: requestLocation,
                        apiCapabilities: apiCapabilities
                    )
                )
                .eraseToAnyPublisher()
            }
        }

        let dataTask = dataTaskPublisher(pagedTarget, progress: progress, requestLocation: requestLocation).share()
        let decoded = dataTask
            .map(\.data)
            .decode(type: E.ResultType.self, decoder: decoder)
            .mapError { error in
                if let decodingError = error as? DecodingError,
                   let annotatedDecodingError = AnnotatedDecodingError(
                    decodingError: decodingError,
                    target: pagedTarget,
                    requestLocation: requestLocation
                   ) {
                    return annotatedDecodingError as Error
                }
                return error
            }
        let info = dataTask.map { _, response -> PagedResult<E.ResultType>.Info in
            var maxId: String?
            var minId: String?
            var sinceId: String?

            if let links = response.value(forHTTPHeaderField: "Link") {
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

            return PagedResult.Info(maxId: maxId, minId: minId, sinceId: sinceId)
        }

        let compatibilityMode = apiCapabilities.compatibilityMode
        return decoded
            .zip(info)
            .map(PagedResult.init(result:info:))
            .tryCatch { error in
                if compatibilityMode == .fallbackOnErrors, let fallback = endpoint.fallback {
                    return Just(
                        PagedResult(
                            result: fallback,
                            info: .init(maxId: nil, minId: nil, sinceId: nil)
                        )
                    )
                    .setFailureType(to: Error.self)
                }
                throw error
            }
            .eraseToAnyPublisher()
    }
}

private extension MastodonAPIClient {
    // swiftlint:disable force_try
    static let linkDataDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    // swiftlint:enable force_try

    func target<E: Endpoint>(endpoint: E) -> MastodonAPITarget<E> {
        MastodonAPITarget(baseURL: instanceURL, endpoint: endpoint, accessToken: accessToken)
    }
}


/// Errors that can be thrown when creating a Mastodon API client.
public enum MastodonAPIClientError: Error {
    /// We only support making Mastodon API calls over HTTPS except for testing purposes.
    case protocolNotSupported(_ scheme: String?)
}
