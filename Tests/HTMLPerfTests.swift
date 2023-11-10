// Copyright © 2023 Vyr Cossont. All rights reserved.

@testable import Mastodon
import XCTest

/// Performance tests for Feditext's HTML parsers.
/// Here and not in the `Mastodon` package because it needs to be app-hosted to run on device
/// (SwiftPM tests can apparently only run in the simulator).
final class HTMLPerfTests: XCTestCase {
    // swiftlint:disable force_try
    static let htmlFragments = try! JSONDecoder().decode(
        [String].self,
        from: Data(
            contentsOf: Bundle(for: HTMLPerfTests.self).url(
                forResource: "public-timeline-html-fragments",
                withExtension: "json"
            )!
        )
    )

    func testHtmlPerfWebKit() {
        parseHtmlFragments(with: .webkit)
    }

    func testHtmlPerfSiren() {
        parseHtmlFragments(with: .siren)
    }

    /// This function relies on the `HTML.parser` global and should not be run concurrently with itself.
    private func parseHtmlFragments(with parser: HTML.Parser) {
        HTML.parser = parser
        measure {
            for htmlFragment in Self.htmlFragments {
                _ = HTML(raw: htmlFragment)
            }
        }
    }
}
