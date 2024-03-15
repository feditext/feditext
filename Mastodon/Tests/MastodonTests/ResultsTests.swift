// Copyright © 2023 Vyr Cossont. All rights reserved.

@testable import Mastodon
import XCTest

final class ResultsTest: XCTestCase {
    /// Deduping a list of identifiable elements should preserve order.
    func testDedupe() throws {
        let tags = [
            Tag(name: "a", url: .init(raw: ""), history: nil, following: true),
            Tag(name: "a", url: .init(raw: ""), history: nil, following: false),
            Tag(name: "b", url: .init(raw: ""), history: nil, following: nil),
        ]
        XCTAssertEqual(2, tags.dedupe().count)
        XCTAssertEqual("a", tags[0].id)
        let following = try XCTUnwrap(tags[0].following)
        XCTAssertTrue(following)
    }
}
