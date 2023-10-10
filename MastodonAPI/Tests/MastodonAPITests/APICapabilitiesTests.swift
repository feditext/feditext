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
}
