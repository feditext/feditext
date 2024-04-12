// Copyright © 2023 Vyr Cossont. All rights reserved.

@testable import Mastodon
import XCTest

/// Performance tests for Feditext's HTML parsers.
/// Here and not in the `Mastodon` package because it needs to be app-hosted to run on device
/// (SwiftPM tests can apparently only run in the simulator).
final class HTMLPerfTests: XCTestCase {
    // swiftlint:disable:next force_try
    static let htmlFragments = try! JSONDecoder().decode(
        [String].self,
        from: Data(
            contentsOf: Bundle(for: HTMLPerfTests.self).url(
                forResource: "public-timeline-html-fragments",
                withExtension: "json"
            )!
        )
    )

    func testHtmlPerf() {
        measure {
            for htmlFragment in Self.htmlFragments {
                _ = HTML(raw: htmlFragment)
            }
        }
    }
}
