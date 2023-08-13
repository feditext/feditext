// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Combine
import CombineExpectations
@testable import ServiceLayer
@testable import ServiceLayerMocks
import Stubbing
import XCTest

final class InstanceURLServiceTests: XCTestCase {
    func testFiltering() throws {
        let sut = InstanceURLService(environment: .mock())

        guard case .success = sut.url(text: "mastodon.social") else {
            XCTFail("Expected success")

            return
        }

        guard case let .failure(error) = sut.url(text: "activitypub-troll.cf"),
              case InstanceURLError.instanceNotSupported = error
        else {
            XCTFail("Expected instance not supported error")

            return
        }

        guard case .failure = sut.url(text: "subdomain.activitypub-troll.cf"),
              case InstanceURLError.instanceNotSupported = error
        else {
            XCTFail("Expected instance not supported error")

            return
        }
    }
}
