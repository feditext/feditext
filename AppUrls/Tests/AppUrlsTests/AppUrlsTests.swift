// Copyright © 2023 Vyr Cossont. All rights reserved.

import XCTest

@testable import AppUrls

final class AppUrlsTests: XCTestCase {
  func testMakeTagTimeline() throws {
    XCTAssertEqual(
      AppUrl.tagTimeline("hashtag").url.absoluteString,
      "feditext:timeline?tag=hashtag"
    )
  }
}
