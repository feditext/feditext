// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "Mastodon",
    platforms: [
        .iOS(.v15),
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
        ),
        .package(path: "AppUrls")
    ],
    targets: [
        .target(
            name: "Mastodon",
            dependencies: ["AppUrls", "SwiftSoup"]),
        .testTarget(
            name: "MastodonTests",
            dependencies: ["Mastodon"])
    ]
)
