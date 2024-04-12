// Copyright © 2024 Metabolist. All rights reserved.

@testable import Feditext
import Foundation
import Mastodon
import UIKit
import XCTest

final class HTMLFormatTests: XCTestCase {
    /// Test that we're hiding the right parts of text containing multiple URLs.
    func testHidePartsOfMultipleURLs() {
        // swiftlint:disable:next line_length
        let html = HTML(raw: #"<p><a href="https://example.org/path/to/a/very/deep/page"><span class="invisible">https://</span><span class="ellipsis">example.org/path/to/a</span><span class="invisible">/very/deep/page</span></a></p><p><a href="https://example.org/path/to/another/very/deep/page"><span class="invisible">https://</span><span class="ellipsis">example.org/path/to/another</span><span class="invisible">/very/deep/page</span></a></p>"#)

        let text = String(html.attrStr.formatSiren(.body).characters)
        XCTAssertEqual(text, "example.org/path/to/a…\n\nexample.org/path/to/another…\n\n")
    }
}
