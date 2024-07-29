// Copyright © 2024 Metabolist. All rights reserved.

import AppMetadata
import Combine
import CombineExpectations
@testable import DB
import Foundation
import Mastodon
import MastodonAPI
import MockKeychain
import Secrets
@testable import ServiceLayer
import ServiceLayerMocks
@testable import ViewModels
import XCTest

final class StatusViewModelTests: XCTestCase {
    enum TestError: Error {
        case identity
    }

    // TODO: (Vyr) this is a horror but most of it can be extracted for use with other tests like this one
    /// Create a status view model from status content HTML and split off the trailing hashtags.
    func splitTrailingHashtags(_ raw: String) throws -> (
        AttributedString,
        AttributedString.Index,
        [StatusViewModel.TagPair]
    ) {
        let instanceURL = URL(string: "https://example.test/")!
        let identityID = UUID(uuidString: "77B84497-2534-4AD9-A862-CDF3FC78DC11")!
        let identityDB = try IdentityDatabase(
            inMemory: true,
            appGroup: AppMetadata.appGroup,
            keychain: MockKeychain.self
        )
        try wait(
            for: identityDB.createIdentity(
                id: identityID,
                url: instanceURL,
                authenticated: true,
                pending: false
            )
            .record()
            .finished,
            timeout: 1
        )
        guard let identity = try wait(
            for: identityDB.identityPublisher(id: identityID, immediate: true)
            .record()
            .availableElements,
            timeout: 1
        ).first else {
            XCTFail("Couldn't get an identity for the test")
            throw TestError.identity
        }

        // Used by `MastodonAPIClient.forIdentity`.
        let secrets = Secrets(identityId: identityID, keychain: MockKeychain.self)
        try secrets.setInstanceURL(instanceURL)
        try secrets.setAccessToken("")
        try secrets.setAPICapabilities(.init())

        let appEnvironment = AppEnvironment.mock(uuid: { identityID })
        let mastodonAPIClient = try MastodonAPIClient.forIdentity(
            id: identityID,
            environment: appEnvironment
        )
        let contentDB = try ContentDatabase(
            id: identityID,
            useHomeTimelineLastReadId: false,
            inMemory: true,
            appGroup: AppMetadata.appGroup,
            keychain: MockKeychain.self
        )

        let html = HTML(raw: raw)
        let now = Date(timeIntervalSince1970: 1722207506)
        let viewModel = StatusViewModel(
            statusService: .init(
                environment: appEnvironment,
                status: .init(
                    id: "",
                    uri: "",
                    createdAt: now,
                    editedAt: nil,
                    account: .init(
                        id: "",
                        username: "",
                        acct: "",
                        displayName: "",
                        locked: false,
                        createdAt: now,
                        followersCount: 0,
                        followingCount: 0,
                        statusesCount: 0,
                        note: .init(raw: ""),
                        url: "",
                        avatar: .init(raw: ""),
                        avatarStatic: .init(raw: ""),
                        header: .init(raw: ""),
                        headerStatic: .init(raw: ""),
                        fields: [],
                        emojis: [],
                        bot: false,
                        group: false,
                        discoverable: false,
                        moved: nil
                    ),
                    content: html,
                    visibility: .public,
                    sensitive: false,
                    spoilerText: "",
                    mediaAttachments: [],
                    mentions: [],
                    tags: [],
                    emojis: [],
                    reblogsCount: 0,
                    favouritesCount: 0,
                    repliesCount: 0,
                    application: nil,
                    url: nil,
                    inReplyToId: nil,
                    inReplyToAccountId: nil,
                    quote: nil,
                    reblog: nil,
                    poll: nil,
                    card: nil,
                    language: nil,
                    text: nil,
                    favourited: false,
                    reblogged: false,
                    muted: false,
                    bookmarked: false,
                    pinned: nil,
                    filtered: [],
                    reactions: []
                ),
                mastodonAPIClient: mastodonAPIClient,
                contentDatabase: contentDB
            ),
            identityContext: .init(
                identity: identity,
                publisher: Empty().eraseToAnyPublisher(),
                service: try .init(
                    id: identityID,
                    database: identityDB,
                    environment: appEnvironment
                ),
                environment: appEnvironment
            ),
            timeline: nil,
            followedTags: [],
            eventsSubject: .init()
        )

        let (startOfTrailer, trailingHashtags) = viewModel.splitTrailingHashtags
        return (html.attrStr, startOfTrailer, trailingHashtags)
    }

    /// This should just not break.
    func testSplitTrailingHashtagsNone() throws {
        let (content, startOfTrailer, trailingHashtags) = try splitTrailingHashtags(
            """
            <p>text</p>
            """
        )
        assert(trailingHashtags.count, equal: 0)
        assert(startOfTrailer, equal: content.endIndex) {
            assert(String(content[..<startOfTrailer].characters), equal: "text")
        }
    }

    /// We expect a single tag directly at the end of text to be left in place.
    func testSplitTrailingHashtagsSingleTagSingleParagraph() throws {
        let (content, startOfTrailer, trailingHashtags) = try splitTrailingHashtags(
            """
            <p>\
            text\
            <a href="https://example.test/tags/foo" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>foo</span></a>\
            </p>
            """
        )
        assert(trailingHashtags, count: 0)
        assert(startOfTrailer, equal: content.endIndex) {
            // There isn't any space between text and first tag because this hasn't been Siren-formatted yet.
            assert(String(content[..<startOfTrailer].characters), equal: "text#foo")
        }
    }

    /// We expect a string of tags directly at the end of text to be split off.
    func testSplitTrailingHashtagsMultipleTagsSingleParagraph() throws {
        let (content, startOfTrailer, trailingHashtags) = try splitTrailingHashtags(
            """
            <p>\
            text\
            <a href="https://example.test/tags/foo" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>foo</span></a>\
            <a href="https://example.test/tags/bar" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>bar</span></a>\
            </p>
            """
        )
        assert(trailingHashtags, count: 2) {
            assert(trailingHashtags[0].id, equal: "foo")
            assert(trailingHashtags[1].id, equal: "bar")
        }
        assert(startOfTrailer, lessThan: content.endIndex) {
            assert(String(content[..<startOfTrailer].characters), equal: "text")
        }
    }

    /// We expect the first hashtag to stay with the text and the second one to be split off.
    func testSplitTrailingHashtagsMultipleTagsLastTagSeparateParagraph() throws {
        let (content, startOfTrailer, trailingHashtags) = try splitTrailingHashtags(
            """
            <p>\
            text\
            <a href="https://example.test/tags/foo" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>foo</span></a>\
            </p>\
            <p>\
            <a href="https://example.test/tags/bar" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>bar</span></a>\
            </p>
            """
        )
        assert(trailingHashtags, count: 1) {
            assert(trailingHashtags[0].id, equal: "bar")
        }
        assert(startOfTrailer, lessThan: content.endIndex) {
            // There isn't any space between text and first tag because this hasn't been Siren-formatted yet.
            assert(String(content[..<startOfTrailer].characters), equal: "text#foo")
        }
    }

    /// We expect a string of tags after the end of the text to be split off.
    func testSplitTrailingHashtagsMultipleTagsSeparateParagraph() throws {
        let (content, startOfTrailer, trailingHashtags) = try splitTrailingHashtags(
            """
            <p>text</p>\
            <p>\
            <a href="https://example.test/tags/foo" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>foo</span></a> \
            <a href="https://example.test/tags/bar" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>bar</span></a>\
            </p>
            """
        )
        assert(trailingHashtags, count: 2) {
            assert(trailingHashtags[0].id, equal: "foo")
            assert(trailingHashtags[1].id, equal: "bar")
        }
        assert(startOfTrailer, lessThan: content.endIndex) {
            assert(String(content[..<startOfTrailer].characters), equal: "text")
        }
    }

    /// We expect a string of tags after the end of text to be split off.
    func testSplitTrailingHashtagsMultipleTagsMultipleParagraphs() throws {
        let (content, startOfTrailer, trailingHashtags) = try splitTrailingHashtags(
            """
            <p>text</p>\
            <p>\
            <a href="https://example.test/tags/foo" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>foo</span></a>\
            </p>\
            <p>\
            <a href="https://example.test/tags/bar" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>bar</span></a>\
            </p>
            """
        )
        assert(trailingHashtags, count: 2) {
            assert(trailingHashtags[0].id, equal: "foo")
            assert(trailingHashtags[1].id, equal: "bar")
        }
        assert(startOfTrailer, lessThan: content.endIndex) {
            assert(String(content[..<startOfTrailer].characters), equal: "text")
        }
    }

    /// We should not drop everything after the last hashtag.
    func testSplitTrailingHashtagsMixedTagsAndText() throws {
        let (content, startOfTrailer, trailingHashtags) = try splitTrailingHashtags(
            """
            <p>\
            <a href="https://example.test/tags/foo" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>foo</span></a>\
            </p>\
            <p>text</p>\
            <p>\
            <a href="https://example.test/tags/bar" class="mention hashtag" \
            rel="tag nofollow noreferrer noopener" target="_blank">#<span>bar</span></a>\
            </p>\
            <p>more</p>
            """
        )
        assert(trailingHashtags, count: 0)
        assert(startOfTrailer, equal: content.endIndex)
    }
}

// TODO: (Vyr) convert to Swift Testing

func assert(
    _ collection: some Collection,
    count: Int,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    block: (() -> Void)? = nil
) {
    XCTAssertEqual(collection.count, count, message(), file: file, line: line)
    if collection.count == count {
        block?()
    }
}

func assert<C: Comparable>(
    _ lhs: C,
    equal rhs: C,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    block: (() -> Void)? = nil
) {
    XCTAssertEqual(lhs, rhs, message(), file: file, line: line)
    if lhs == rhs {
        block?()
    }
}

func assert<C: Comparable>(
    _ lhs: C,
    lessThan rhs: C,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    block: (() -> Void)? = nil
) {
    XCTAssertLessThan(lhs, rhs, message(), file: file, line: line)
    if lhs < rhs {
        block?()
    }
}
