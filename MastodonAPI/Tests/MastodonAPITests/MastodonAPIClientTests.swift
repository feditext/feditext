// Copyright © 2023 Vyr Cossont. All rights reserved.

import AppUrls
import Combine
import Foundation
import Mastodon
@testable import MastodonAPI
import XCTest

/// Exercise the Mastodon API client.
/// These are integration tests and talk to a real server.
final class MastodonAPIClientTests: XCTestCase {
    var instanceURL: URL!
    var username: String?
    var password: String?
    var accessToken: String?
    var gotoSocialTestrigRealVersion: String?

    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let scopes = "read write push admin:read admin:write"

    /// Run only if our environment contains the URL to a test server.
    override func setUpWithError() throws {
        instanceURL = ProcessInfo.processInfo
            .environment["MASTODON_API_TEST_INSTANCE_URL"]
            .flatMap(URL.init(string:))
        if instanceURL == nil {
            throw XCTSkip("""
                MASTODON_API_TEST_INSTANCE_URL env var not set or URL not valid. \
                Skipping API integration tests.
                """
            )
        }

        username = ProcessInfo.processInfo
            .environment["MASTODON_API_TEST_USERNAME"]

        password = ProcessInfo.processInfo
            .environment["MASTODON_API_TEST_PASSWORD"]

        accessToken = ProcessInfo.processInfo
            .environment["MASTODON_API_TEST_ACCESS_TOKEN"]

        gotoSocialTestrigRealVersion = ProcessInfo.processInfo
            .environment["MASTODON_API_TEST_GOTOSOCIAL_TESTRIG_REAL_VERSION"]
    }

    /// Return an unauthenticated client with API capabilities detected.
    func unauthenticatedClient() async throws -> MastodonAPIClient {
        let nodeInfo = try await NodeInfoClient(
            session: .shared,
            instanceURL: instanceURL,
            allowUnencryptedHTTP: true
        )
            .nodeInfo()

        var apiCapabilities = APICapabilities(nodeInfo: nodeInfo)

        // GotoSocial's test rig doesn't report a real version, so we allow overriding it.
        if apiCapabilities.flavor == .gotosocial,
           apiCapabilities.version == "0.0.0",
           let gotoSocialTestrigRealVersion = gotoSocialTestrigRealVersion {
            apiCapabilities = .init(
                flavor: apiCapabilities.flavor,
                version: .init(stringLiteral: gotoSocialTestrigRealVersion),
                features: apiCapabilities.features,
                compatibilityMode: apiCapabilities.compatibilityMode
            )
        }

        let bootstrapClient = try MastodonAPIClient(
            session: .shared,
            instanceURL: self.instanceURL,
            apiCapabilities: apiCapabilities,
            accessToken: nil,
            allowUnencryptedHTTP: true
        )

        let instance = try await bootstrapClient
            .request(InstanceEndpoint.instance)
            .onlyValue

        apiCapabilities.setDetectedFeatures(instance)

        return try MastodonAPIClient(
            session: .shared,
            instanceURL: self.instanceURL,
            apiCapabilities: apiCapabilities,
            accessToken: nil,
            allowUnencryptedHTTP: true
        )
    }

    /// Test API capaibility detection.
    func testDetectAPICapabilities() async throws {
        _ = try await unauthenticatedClient()
    }

    /// Test fetching instance info.
    func testInstance() async throws {
        let client = try await unauthenticatedClient()

        let instance = try await client
            .request(InstanceEndpoint.instance)
            .onlyValue

        XCTAssertGreaterThan(instance.stats.userCount, 0)
    }

    /// Test request progress tracking.
    func testProgress() async throws {
        let client = try await unauthenticatedClient()
        let progress = Progress(totalUnitCount: 1)

        XCTAssertEqual(progress.fractionCompleted, 0)

        _ = try await client
            .request(
                InstanceEndpoint.instance,
                progress: progress
            )
            .onlyValue

        XCTAssertEqual(progress.fractionCompleted, 1)
    }

    /// Register an OAuth application.
    func registerApp(_ client: MastodonAPIClient) async throws -> (clientID: String, clientSecret: String) {
        let client = try await unauthenticatedClient()

        let appAuthorization = try await client
            .request(AppAuthorizationEndpoint.apps(
                clientName: "Feditext test suite",
                redirectURI: Self.redirectURI,
                scopes: Self.scopes,
                website: AppUrl.website
            ))
            .onlyValue

        return (appAuthorization.clientId, appAuthorization.clientSecret)
    }

    /// Test registering an OAuth application.
    func testRegisterApp() async throws {
        let client = try await unauthenticatedClient()

        let (clientID, clientSecret) = try await registerApp(client)

        XCTAssert(!clientID.isEmpty)
        XCTAssert(!clientSecret.isEmpty)
    }

    /// Get an OAuth access token with a username and password.
    /// Support for the OAuth `password` grant type is undocumented by Mastodon and may not exist for other servers.
    /// - Note: GotoSocial does not support `password`.
    func getAccessTokenWithPasswordFlow(
        _ client: MastodonAPIClient,
        _ clientID: String,
        _ clientSecret: String
    ) async throws -> String {
        guard let username = username,
              let password = password
        else {
            throw XCTSkip("MASTODON_API_TEST_USERNAME or MASTODON_API_TEST_PASSWORD env var not set.")
        }

        let client = try await unauthenticatedClient()

        let result = try await client
            .request(AccessTokenEndpoint.oauthToken(
                clientId: clientID,
                clientSecret: clientSecret,
                grantType: "password",
                scopes: Self.scopes,
                code: nil,
                username: username,
                password: password,
                redirectURI: nil // Not used in password flow.
            ))
            .onlyValue

        return result.accessToken
    }

    /// Test getting an OAuth access token with a username and password.
    func testGetAccessTokenWithPasswordFlow() async throws {
        let client = try await unauthenticatedClient()
        guard supportsPasswordFlow(client.apiCapabilities) else {
            let flavor = client.apiCapabilities.flavor?.rawValue ?? "Unknown server flavor"
            throw XCTSkip("\(flavor) does not support the OAuth password flow")
        }

        let (clientID, clientSecret) = try await registerApp(client)

        let accessToken = try await getAccessTokenWithPasswordFlow(client, clientID, clientSecret)

        XCTAssert(!accessToken.isEmpty)
    }

    func supportsPasswordFlow(_ apiCapabilities: APICapabilities) -> Bool {
        apiCapabilities.flavor != .gotosocial
    }

    /// Registers an app, logs in with a username and password, and gets an access token.
    func authenticatedClient() async throws -> MastodonAPIClient {
        let client = try await unauthenticatedClient()

        let accessToken: String?
        if let environmentAccessToken = self.accessToken {
            accessToken = environmentAccessToken
        } else if supportsPasswordFlow(client.apiCapabilities) {
            let (clientID, clientSecret) = try await registerApp(client)
            accessToken = try await getAccessTokenWithPasswordFlow(client, clientID, clientSecret)
        } else {
            throw XCTSkip("""
                MASTODON_API_TEST_ACCESS_TOKEN env var not set. \
                Skipping API integration tests that require authentication.
                """
            )
        }

        return try MastodonAPIClient(
            session: .shared,
            instanceURL: self.instanceURL,
            apiCapabilities: client.apiCapabilities,
            accessToken: accessToken,
            allowUnencryptedHTTP: true
        )
    }

    /// Try fetching the home timeline, which requires authentication.
    func testHomeTimeline() async throws {
        let client = try await authenticatedClient()

        let timeline = try await client
            .request(StatusesEndpoint.timelinesHome)
            .onlyValue

        XCTAssert(!timeline.isEmpty)
    }
}

extension Publisher {
    /// Equivalent of `Future.value` for a publisher that can return multiple values
    /// but where we expect it to only return one.
    var onlyValue: Output {
        get async throws {
            var valuesIter = values.makeAsyncIterator()
            guard let first = try await valuesIter.next() else {
                XCTFail("onlyValue: Nothing returned")
                throw TestHelperError.noValues
            }

            guard try await valuesIter.next() == nil else {
                XCTFail("onlyValue: Too many values returned")
                throw TestHelperError.tooManyValues
            }

            return first
        }
    }
}

enum TestHelperError: Error {
    case noValues
    case tooManyValues
}
