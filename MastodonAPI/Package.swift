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
            targets: ["MastodonAPIStubs"]),
        .executable(
            name: "MastodonAPITool",
            targets: ["MastodonAPITool"])
    ],
    dependencies: [
        .package(path: "AppMetadata"),
        .package(path: "CombineInterop"),
        .package(path: "HTTP"),
        .package(path: "Mastodon"),
        .package(url: "https://github.com/ddddxxx/Semver.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "MastodonAPI",
            dependencies: ["AppMetadata", "CombineInterop", "HTTP", "Mastodon", "Semver"]),
        .target(
            name: "MastodonAPIStubs",
            dependencies: ["MastodonAPI", .product(name: "Stubbing", package: "HTTP")],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MastodonAPITests",
            dependencies: ["MastodonAPIStubs"]),
        .executableTarget(
            name: "MastodonAPITool",
            dependencies: [
                "MastodonAPI",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ])
    ]
)
