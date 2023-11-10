// Copyright © 2023 Vyr Cossont. All rights reserved.

@testable import Mastodon
import XCTest

final class HTMLTests: XCTestCase {
    /// Parsing HTML mentioning two accounts with the same mention text and username part,
    /// but different URLs, should produce two mentions.
    /// - See: https://github.com/feditext/feditext/issues/101
    func testMultipleMentionsWithSameUsernamePart() {
        multipleMentionsWithSameUsernamePart(parser: .webkit)
    }

    func testMultipleMentionsWithSameUsernamePartSiren() {
        multipleMentionsWithSameUsernamePart(parser: .siren)
    }
    private func multipleMentionsWithSameUsernamePart(parser: HTML.Parser) {
        HTML.parser = parser

        // swiftlint:disable:next line_length
        let html = HTML(raw: #"<p><span class="h-card"><a href="https://octodon.social/@Kadsenchaos" class="u-url mention" rel="nofollow noreferrer noopener" target="_blank">@<span>Kadsenchaos</span></a></span> <span class="h-card"><a href="https://blahaj.zone/@Kadsenchaos" class="u-url mention" rel="nofollow noreferrer noopener" target="_blank">@<span>Kadsenchaos</span></a></span> hmm, mal sehen, ob das überhaupt mit meinem GtS sauber föderiert, hatte da den anderen Tag Probleme mit</p>"#)

        // Check that the semantic class parsing has found the mentions we expect.

        let expectedMentions: [(text: String, url: URL)] = [
            ("@Kadsenchaos", URL(string: "feditext:mention?url=https://octodon.social/@Kadsenchaos")!),
            ("@Kadsenchaos", URL(string: "feditext:mention?url=https://blahaj.zone/@Kadsenchaos")!)
        ]

        var actualMentions = [(text: String, url: URL)]()
        let entireString = NSRange(location: 0, length: html.attributed.length)
        html.attributed.enumerateAttribute(HTML.Key.linkClass, in: entireString) { val, nsRange, _ in
            guard let linkClass = val as? HTML.LinkClass, linkClass == .mention else { return }

            guard let range = Range(nsRange, in: html.attributed.string) else {
                XCTFail("Getting the substring range should always succeed")
                return
            }

            guard let url = html.attributed.attribute(
                .link,
                at: nsRange.location,
                effectiveRange: nil
            ) as? URL else {
                XCTFail("Getting the link for a span with a linkClass should always succeed")
                return
            }

            let text = String(html.attributed.string[range])

            actualMentions.append((text, url))
        }

        XCTAssertEqual(
            expectedMentions.count,
            actualMentions.count,
            "Expected to find \(expectedMentions.count) mentions, found \(actualMentions.count)"
        )
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
        html.attributed.enumerateAttribute(.link, in: entireString) { val, _, _ in
            guard let url = val as? URL else { return }

            actualLinks.append(url)
        }

        XCTAssertEqual(expectedLinks, actualLinks)
    }

    /// Hashtags should be detected if they have the `hashtag` semantic class,
    /// regardless of whether they also have `mention`.
    /// Mastodon and GotoSocial both send `mention hashtag` for hashtags but others might not.
    func testHashtagVariants() {
        hashtagVariants(parser: .webkit)
    }

    func testHashtagVariantsSiren() {
        hashtagVariants(parser: .siren)
    }

    private func hashtagVariants(parser: HTML.Parser) {
        HTML.parser = parser

        // swiftlint:disable:next line_length
        let html = HTML(raw: #"<p><span class="h-card"><a href="https://example.org/@Feditext" class="u-url mention" rel="nofollow noreferrer noopener" target="_blank">@<span>Feditext</span></a></span> <a href="https://example.org/tags/foo" class="hashtag" rel="tag nofollow noreferrer noopener" target="_blank">#<span>foo</span></a> <a href="https://example.org/tags/bar" class="mention hashtag" rel="tag nofollow noreferrer noopener" target="_blank">#<span>bar</span></a></p>"#)

        // Check that the semantic class parsing has found the mentions we expect.

        let expectedHashtags: [(text: String, url: URL)] = [
            ("#foo", URL(string: "feditext:timeline?tag=foo")!),
            ("#bar", URL(string: "feditext:timeline?tag=bar")!)
        ]

        var actualHashtags = [(text: String, url: URL)]()
        let entireString = NSRange(location: 0, length: html.attributed.length)
        html.attributed.enumerateAttribute(HTML.Key.linkClass, in: entireString) { val, nsRange, _ in
            guard let linkClass = val as? HTML.LinkClass, linkClass == .hashtag else { return }

            guard let range = Range(nsRange, in: html.attributed.string) else {
                XCTFail("Getting the substring range should always succeed")
                return
            }

            guard let url = html.attributed.attribute(
                .link,
                at: nsRange.location,
                effectiveRange: nil
            ) as? URL else {
                XCTFail("Getting the link for a span with a linkClass should always succeed")
                return
            }

            let text = String(html.attributed.string[range])

            actualHashtags.append((text, url))
        }

        XCTAssertEqual(
            expectedHashtags.count,
            actualHashtags.count,
            "Expected to find \(expectedHashtags.count) hashtags, found \(actualHashtags.count)"
        )
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
