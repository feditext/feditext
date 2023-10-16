// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

/// Mid-level HTTP client wrapping `URLSession`.
/// Provides response decoding, some error handling, and enables request stubbing in test scenarios.
public struct HTTPClient: Sendable {
    private let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    /// Request something and decode it, returning the decoded object, and the response for higher-level error handling and paging.
    public func request<T: DecodableTarget>(
        _ target: T,
        progress: Progress? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) async throws -> (decoded: T.ResultType, response: HTTPURLResponse) {
        let requestLocation = DebugLocation(file: file, line: line, function: function)

        if let protocolClasses = session.configuration.protocolClasses {
            for protocolClass in protocolClasses {
                (protocolClass as? TargetProcessing.Type)?.process(target: target)
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(
                for: target.urlRequest(),
                delegate: progress.map(ProgressDelegate.init(progress:))
            )
        } catch let urlError as URLError {
            throw AnnotatedURLError(
                urlError: urlError,
                target: target,
                requestLocation: requestLocation
            ) ?? urlError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError(
                target: target,
                requestLocation: requestLocation
            )
        }

        guard Self.validStatusCodes.contains(httpResponse.statusCode) else {
            throw HTTPError(
                target: target,
                data: data,
                httpResponse: httpResponse,
                requestLocation: requestLocation
            )
        }

        let decoded: T.ResultType
        do {
            decoded = try target.decoder.decode(T.ResultType.self, from: data)
        } catch let decodingError as DecodingError {
            throw AnnotatedDecodingError(
                decodingError: decodingError,
                target: target,
                requestLocation: requestLocation
            ) ?? decodingError
        }

        return (decoded, httpResponse)
    }

    /// HTTP status codes that indicate success.
    private static let validStatusCodes = 200..<300

    /// Used to link an async data request to a ``Progress`` object.
    private final class ProgressDelegate: NSObject, URLSessionTaskDelegate {
        let progress: Progress

        init(progress: Progress) {
            self.progress = progress
        }

        func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
            progress.addChild(task.progress, withPendingUnitCount: 1)
        }
    }
}
