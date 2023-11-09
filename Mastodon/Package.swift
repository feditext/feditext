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
        .package(path: "AppMetadata"),
        .package(path: "AppUrls"),
        .package(path: "Siren"),
        .package(
            url: "https://github.com/scinfu/SwiftSoup.git",
            from: "2.6.1"
        )
    ],
    targets: [
        .target(
            name: "Mastodon",
            dependencies: ["AppMetadata", "AppUrls", "Siren", "SwiftSoup"]),
        .testTarget(
            name: "MastodonTests",
            dependencies: ["Mastodon"])
    ]
)
