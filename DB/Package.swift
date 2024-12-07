// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "DB",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "DB",
            targets: ["DB"])
    ],
    dependencies: [
        .package(path: "AppMetadata"),
        .package(url: "https://github.com/feditext/GRDB.swift.git", revision: "3ceeed29f"),
        .package(path: "Mastodon"),
        .package(path: "Secrets")
    ],
    targets: [
        .target(
            name: "DB",
            dependencies: [
                "AppMetadata",
                .product(name: "GRDB", package: "GRDB.swift"),
                "Mastodon",
                "Secrets"
            ]
        ),
        .testTarget(
            name: "DBTests",
            dependencies: ["DB"])
    ]
)
