// Copyright © 2023 Vyr Cossont. All rights reserved.

import ArgumentParser
import Foundation
import Mastodon
import MastodonAPI

/// Command-line API client and benchmarking utility for Feditext HTML parsers.
@main
struct MastodonAPITool: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Benchmarking tool for Feditext components.",
        subcommands: [Fetch.self, Bench.self]
    )

    struct TimelineFileOptions: ParsableArguments {
        @Argument(
            help: "The recorded timeline data file to load or save.",
            completion: .file(),
            transform: URL.init(fileURLWithPath:)
        )
        var dataFile: URL
    }

    // TODO: (Vyr) doesn't understand rate limits
    struct Fetch: AsyncParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Fetch some posts from a public federated timeline."
        )

        @OptionGroup var options: TimelineFileOptions

        @Option(help: "Approximate number of timeline posts to fetch.")
        var count: Int = 1000

        @Option(
            help: "Instance to fetch from.",
            transform: { raw in
                if let url = URL(string: raw) {
                    return url
                }
                throw ValidationError("Couldn't parse URL")
            }
        )
        var instanceURL: URL = URL(string: "https://mastodon.social/")!

        mutating func run() async throws {
            let client = try MastodonAPIClient(
                session: .shared,
                instanceURL: instanceURL,
                apiCapabilities: .unknown,
                accessToken: nil,
                allowUnencryptedHTTP: true
            )

            var htmlFragments = [String]()
            var maxId: String?
            while htmlFragments.count < count {
                let page = try await client.pagedRequest(
                    StatusesEndpoint.timelinesPublic(local: false),
                    maxId: maxId
                )
                maxId = page.info.maxId
                htmlFragments.append(contentsOf: page.result.compactMap { status in
                    let htmlFragment = status.content.raw
                    return if htmlFragment.isEmpty { nil } else { htmlFragment }
                })
            }

            try JSONEncoder().encode(htmlFragments).write(to: options.dataFile)
        }
    }

    struct Bench: AsyncParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Benchmark HTML parsing with WebKit and Siren on the same set of posts."
        )

        @OptionGroup var options: TimelineFileOptions

        mutating func run() async throws {
            let htmlFragments = try JSONDecoder().decode([String].self, from: Data(contentsOf: options.dataFile))

            print("total input HTML fragments: \(htmlFragments.count)")
            print()

            for parser in HTML.Parser.allCases {
                HTML.parser = parser

                // If we print some function of the actual output, the parsing can't get optimized out.
                var outputCharCount = 0
                var emptyOutputStrings = 0
                var worstParseTime: TimeInterval = 0

                let startTime = ProcessInfo.processInfo.systemUptime
                for htmlFragment in htmlFragments {
                    let fragmentStartTime = ProcessInfo.processInfo.systemUptime
                    let parsed = HTML(raw: htmlFragment).attributed
                    let fragmentEndTime = ProcessInfo.processInfo.systemUptime

                    outputCharCount += parsed.string.count
                    if parsed.string.isEmpty {
                        emptyOutputStrings += 1
                    }
                    let fragmentElapsedTime = fragmentEndTime - fragmentStartTime
                    worstParseTime = max(worstParseTime, fragmentElapsedTime)
                }
                let endTime = ProcessInfo.processInfo.systemUptime

                let elapsedTime = endTime - startTime

                print("parser: \(parser.rawValue)")
                print("elapsed time (s): \(String(format: "%.1f", elapsedTime))")
                print("average time per input string (ms): \(String(format: "%.0f", 1000 * elapsedTime / Double(htmlFragments.count)))")
                print("worst time for any input string (ms): \(String(format: "%.0f", 1000 * worstParseTime))")
                print("total output chars: \(outputCharCount)")
                print("total empty output strings: \(emptyOutputStrings)")
                print()
            }
        }
    }
}
