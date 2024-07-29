// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "ViewModels",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "ViewModels",
            targets: ["ViewModels"]
        ),
        .library(
            name: "PreviewViewModels",
            targets: ["PreviewViewModels"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/CombineExpectations.git", .upToNextMajor(from: "0.7.0")),
        .package(path: "AppUrls"),
        .package(path: "Common"),
        .package(path: "ServiceLayer"),
    ],
    targets: [
        .target(
            name: "ViewModels",
            dependencies: ["AppUrls", "Common", "ServiceLayer"]),
        .target(
            name: "PreviewViewModels",
            dependencies: ["ViewModels", .product(name: "ServiceLayerMocks", package: "ServiceLayer")]
        ),
        .testTarget(
            name: "ViewModelsTests",
            dependencies: ["CombineExpectations", "PreviewViewModels"]
        ),
    ]
)
