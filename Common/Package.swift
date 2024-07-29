// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Common",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "Common",
            targets: ["Common"]
        ),
    ],
    targets: [
        .target(
            name: "Common"
        ),
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"]
        ),
    ]
)
