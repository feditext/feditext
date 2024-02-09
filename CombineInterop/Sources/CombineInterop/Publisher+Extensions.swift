// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Foundation

public extension Publisher {
    /// We want to run another publisher that never returns values as a side effect, such as storing the output
    /// in the DB, but pass through the original value since we don't care about the result of that.
    /// If the side effect fails, this should still fail as well.
    func andAlso<P>(_ also: @escaping (Output) -> P) -> AnyPublisher<Output, Failure>
        where P: Publisher, P.Output == Never, P.Failure == Failure {
        flatMap { value in
            also(value)
                // It's okay that this line is never executed:
                .flatMap { _ in Empty(outputType: Output.self, failureType: Failure.self) }
                .prepend(value)
        }
        .eraseToAnyPublisher()
    }

    /// Combine doesn't have `andThen`: https://stackoverflow.com/a/58734595
    func andThen<P>(_ then: @escaping () -> P) -> AnyPublisher<P.Output, Failure>
        where P: Publisher, P.Failure == Failure {
            flatMap { _ in Empty(outputType: P.Output.self, failureType: Failure.self) }
                .append(then())
                .eraseToAnyPublisher()
    }

    func asyncMap<T>(_ transform: @Sendable @escaping (Output) async -> T) -> AnyPublisher<T, Failure> {
        flatMap { output in
            Future<T, Failure> { await transform(output) }
        }
        .eraseToAnyPublisher()
    }

    func asyncTryMap<T>(_ transform: @Sendable @escaping (Output) async throws -> T) -> AnyPublisher<T, Error> {
        mapError { $0 }
            .flatMap { output in
                Future { try await transform(output) }
            }
            .eraseToAnyPublisher()
    }
}

public extension Publisher where Output == Never, Failure == Never {
    var finished: () {
        get async {
            var valuesIter = values.makeAsyncIterator()

            while await valuesIter.next() != nil {
                fatalError("Too many values published")
            }
        }
    }
}

public extension Publisher where Output == Never {
    var finished: () {
        get async throws {
            var valuesIter = values.makeAsyncIterator()

            while try await valuesIter.next() != nil {
                fatalError("Too many values published")
            }
        }
    }
}

public extension Publisher where Failure == Never {
    var singleValue: Output {
        get async {
            var valuesIter = values.makeAsyncIterator()
            guard let first = await valuesIter.next() else {
                 fatalError("No values published")
            }

            while await valuesIter.next() != nil {
                fatalError("Too many values published")
            }

            return first
        }
    }

    var finalValue: Output {
        get async {
            var valuesIter = values.makeAsyncIterator()
            var last: Output?

            while true {
                if let value = await valuesIter.next() {
                    last = value
                } else {
                    if let last = last {
                        return last
                    }
                    fatalError("No values published")
                }
            }
        }
    }
}

public extension Publisher {
    var singleValue: Output {
        get async throws {
            var valuesIter = values.makeAsyncIterator()
            guard let first = try await valuesIter.next() else {
                 fatalError("No values published")
            }

            while try await valuesIter.next() != nil {
                fatalError("Too many values published")
            }

            return first
        }
    }

    var finalValue: Output {
        get async throws {
            var valuesIter = values.makeAsyncIterator()
            var last: Output?

            while true {
                if let value = try await valuesIter.next() {
                    last = value
                } else {
                    if let last = last {
                        return last
                    }
                    fatalError("No values published")
                }
            }
        }
    }
}
