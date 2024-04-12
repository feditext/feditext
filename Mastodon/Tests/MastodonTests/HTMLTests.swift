// Copyright © 2023 Vyr Cossont. All rights reserved.

@testable import Mastodon
import XCTest

final class HTMLTests: XCTestCase {
    /// Parsing HTML mentioning two accounts with the same mention text and username part,
    /// but different URLs, should produce two mentions.
    /// - See: https://github.com/feditext/feditext/issues/101
    func testMultipleMentionsWithSameUsernamePart() {
        // swiftlint:disable:next line_length
        let html = HTML(raw: #"<p><span class="h-card"><a href="https://octodon.social/@Kadsenchaos" class="u-url mention" rel="nofollow noreferrer noopener" target="_blank">@<span>Kadsenchaos</span></a></span> <span class="h-card"><a href="https://blahaj.zone/@Kadsenchaos" class="u-url mention" rel="nofollow noreferrer noopener" target="_blank">@<span>Kadsenchaos</span></a></span> hmm, mal sehen, ob das überhaupt mit meinem GtS sauber föderiert, hatte da den anderen Tag Probleme mit</p>"#)

        // Check that the semantic class parsing has found the mentions we expect.

        let expectedMentions: [(text: String, url: URL)] = [
            ("@Kadsenchaos", URL(string: "feditext:mention?url=https://octodon.social/@Kadsenchaos")!),
            ("@Kadsenchaos", URL(string: "feditext:mention?url=https://blahaj.zone/@Kadsenchaos")!)
        ]

        var actualMentions = [(text: String, url: URL)]()
        for (linkClass, range) in html.attrStr.runs[\.linkClass] {
            guard let linkClass = linkClass, linkClass == .mention else { continue }

            guard let url = html.attrStr[range].link else {
                XCTFail("Getting the link for a span with a linkClass should always succeed")
                return
            }

            let text = String(html.attrStr.characters[range])

            actualMentions.append((text, url))
        }

        if expectedMentions.count != actualMentions.count {
            XCTFail("Expected to find \(expectedMentions.count) mentions, found \(actualMentions.count)")
            return
        }
        for i in 0..<expectedMentions.count {
            let expectedMention = expectedMentions[i]
            let actualMention = actualMentions[i]
            XCTAssertEqual(
                expectedMention.text,
                actualMention.text,
                "Mention \(i): Expected mention text \(expectedMention.text), got \(actualMention.text)"
            )
            XCTAssertEqual(
                expectedMention.url,
                actualMention.url,
                "Mention \(i): Expected mention URL \(expectedMention.url), got \(actualMention.url)"
            )
        }

        // Find all the links that exist, which should only be mention links in this case.

        let expectedLinks = expectedMentions.map(\.url)

        var actualLinks = [URL]()
        for (url, _) in html.attrStr.runs[\.link] {
            guard let url = url else { return }

            actualLinks.append(url)
        }

        XCTAssertEqual(expectedLinks, actualLinks)
    }

    /// Hashtags should be detected if they have the `hashtag` semantic class,
    /// regardless of whether they also have `mention`.
    /// Mastodon and GotoSocial both send `mention hashtag` for hashtags but others might not.
    func testHashtagVariants() {
        // swiftlint:disable:next line_length
        let html = HTML(raw: #"<p><span class="h-card"><a href="https://example.org/@Feditext" class="u-url mention" rel="nofollow noreferrer noopener" target="_blank">@<span>Feditext</span></a></span> <a href="https://example.org/tags/foo" class="hashtag" rel="tag nofollow noreferrer noopener" target="_blank">#<span>foo</span></a> <a href="https://example.org/tags/bar" class="mention hashtag" rel="tag nofollow noreferrer noopener" target="_blank">#<span>bar</span></a></p>"#)

        // Check that the semantic class parsing has found the mentions we expect.

        let expectedHashtags: [(text: String, url: URL)] = [
            ("#foo", URL(string: "feditext:timeline?tag=foo")!),
            ("#bar", URL(string: "feditext:timeline?tag=bar")!)
        ]

        var actualHashtags = [(text: String, url: URL)]()
        for (linkClass, range) in html.attrStr.runs[\.linkClass] {
            guard let linkClass = linkClass, linkClass == .hashtag else { continue }

            guard let url = html.attrStr[range].link else {
                XCTFail("Getting the link for a span with a linkClass should always succeed")
                return
            }

            let text = String(html.attrStr.characters[range])

            actualHashtags.append((text, url))
        }

        if expectedHashtags.count != actualHashtags.count {
            XCTFail("Expected to find \(expectedHashtags.count) hashtags, found \(actualHashtags.count)")
            return
        }
        for i in 0..<expectedHashtags.count {
            let expectedHashtag = expectedHashtags[i]
            let actualHashtag = actualHashtags[i]
            XCTAssertEqual(
                expectedHashtag.text,
                actualHashtag.text,
                "Hashtag \(i): Expected hashtag text \(expectedHashtag.text), got \(actualHashtag.text)"
            )
            XCTAssertEqual(
                expectedHashtag.url,
                actualHashtag.url,
                "Hashtag \(i): Expected hashtag URL \(expectedHashtag.url), got \(actualHashtag.url)"
            )
        }
    }
}
