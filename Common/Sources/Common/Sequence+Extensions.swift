// Copyright © 2024 Vyr Cossont. All rights reserved.

import Foundation

public extension Sequence {
    /// Like ``String.joined`` but for ``AttributedString``.
    func joined(separator: AttributedString = .init()) -> AttributedString where Element == AttributedString {
        var acc = AttributedString()
        var first = true
        for part in self {
            if first {
                first = false
            } else {
                acc += separator
            }
            acc += part
        }
        return acc
    }

    /// Like ``String.joined`` but for ``AttributedString``.
    func joined(separator: String = "") -> AttributedString where Element == AttributedString {
        joined(separator: .init(separator))
    }

    /// De-duplicate the sequence using a key extractor function.
    func unique<T>(by extractKey: @escaping (Element) -> T) -> some Sequence<Element> where T: Hashable {
        var seen = Set<T>()
        return self.compactMap { element in
            let key = extractKey(element)
            if seen.contains(key) {
                return nil
            }
            seen.insert(key)
            return element
        }
    }

    /// De-duplicate the sequence using each element's ``id``.
    func unique() -> some Sequence<Element> where Element: Identifiable {
        unique(by: \.id)
    }
}
