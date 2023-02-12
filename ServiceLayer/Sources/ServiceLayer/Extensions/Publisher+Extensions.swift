// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Foundation

extension Publisher {
    /// We want to run another publisher that never returns values as a side effect, such as storing the output in the DB,
    /// but pass through the original value since we don't care about the result of that.
    /// If the side effect fails, this should still fail as well.
    ///
    /// > Note: Combine doesn't have `andThen`: https://stackoverflow.com/a/58734595
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
}
