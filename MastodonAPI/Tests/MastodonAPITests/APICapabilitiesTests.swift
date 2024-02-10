// Copyright © 2023 Vyr Cossont. All rights reserved.

@testable import MastodonAPI
import XCTest

final class APICapabilitiesTests: XCTestCase {
    /// Test that a string known to be a valid semver can be parsed into all the useful parts.
    func testStrictSemver() {
        let apiCapabilities = APICapabilities(
            nodeinfoSoftware: .init(
                name: "mastodon",
                version: "4.1.3+glitch"
            )
        )

        guard let version = apiCapabilities.version else {
            XCTFail("Couldn't parse version at all")
            return
        }

        XCTAssertEqual(version.major, 4)
        XCTAssertEqual(version.minor, 1)
        XCTAssertEqual(version.patch, 3)
        XCTAssertNil(version.prereleaseString)
        XCTAssertEqual(version.buildMetadataString, "glitch")
    }

    /// Test that a string known not to be a valid semver can still be parsed using the fallback parser.
    func testRelaxedSemver() {
        let apiCapabilities = APICapabilities(
            nodeinfoSoftware: .init(
                name: "mastodon",
                version: "4.1.3+glitch+cutiecity"
            )
        )

        guard let version = apiCapabilities.version else {
            XCTFail("Couldn't parse version at all")
            return
        }

        // We expect only the numeric version…
        XCTAssertEqual(version.major, 4)
        XCTAssertEqual(version.minor, 1)
        XCTAssertEqual(version.patch, 3)

        // …and not the malformed build metadata.
        XCTAssertNil(version.prereleaseString)
        XCTAssertNil(version.buildMetadataString)
    }

    /// Test that a string with fewer than 3 numeric version components will still be parsed.
    func testShortNumeric() {
        let apiCapabilities = APICapabilities(
            nodeinfoSoftware: .init(
                name: "mastodon",
                version: "4.1"
            )
        )

        guard let version = apiCapabilities.version else {
            XCTFail("Couldn't parse version at all")
            return
        }

        // We expect only the major and minor numeric version, with a default patch numeric version.
        XCTAssertEqual(version.major, 4)
        XCTAssertEqual(version.minor, 1)
        XCTAssertEqual(version.patch, 0)
    }

    /// Test that these don't crash the parser. Hopefully this doesn't get optimized out when testing.
    func testWeird() {
        for versionString in ["", " ", "-", "0.4rc3", "aleph", "git-890fe4b", "4.3.0-alpha.1+glitch"] {
            _ = APICapabilities(
                nodeinfoSoftware: .init(
                    name: "mastodon",
                    version: versionString
                )
            )
        }
    }
}
