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
}
