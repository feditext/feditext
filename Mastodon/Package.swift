// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Mastodon",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Mastodon",
            targets: ["Mastodon"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/scinfu/SwiftSoup.git",
            from: "2.4.3"
        )
    ],
    targets: [
        .target(
            name: "Mastodon",
            dependencies: ["SwiftSoup"]),
        .testTarget(
            name: "MastodonTests",
            dependencies: ["Mastodon"])
    ]
)
