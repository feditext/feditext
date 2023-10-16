// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MastodonAPI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MastodonAPI",
            targets: ["MastodonAPI"]),
        .library(
            name: "MastodonAPIStubs",
            targets: ["MastodonAPIStubs"])
    ],
    dependencies: [
        .package(path: "HTTP"),
        .package(path: "Mastodon"),
        .package(url: "https://github.com/ddddxxx/Semver.git", .upToNextMinor(from: "0.2.0"))
    ],
    targets: [
        .target(
            name: "MastodonAPI",
            dependencies: ["HTTP", "Mastodon", "Semver"]),
        .target(
            name: "MastodonAPIStubs",
            dependencies: ["MastodonAPI", .product(name: "Stubbing", package: "HTTP")],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MastodonAPITests",
            dependencies: ["MastodonAPIStubs"])
    ]
)
