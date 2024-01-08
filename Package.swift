// swift-tools-version:5.7

// 📜 https://github.com/apple/swift-package-manager/blob/main/Documentation/PackageDescription.md
import PackageDescription

#if os(Linux)
let products: [Product] = [
    .library(
        name: "Blocks",
        targets: ["Blocks"]
    )
]
#else
let products: [Product] = [
    .library(
        name: "Blocks",
        targets: ["Blocks"]
    ),
    .library(
        name: "ObjectiveBlocks",
        targets: ["ObjectiveBlocks"]
    )
]
#endif

#if os(Linux)
let targets: [Target] = [
    .target(
        name: "Blocks",
        dependencies: []
    ),
    .testTarget(
        name: "BlocksTests",
        dependencies: ["Blocks"],
        resources: [.process("Resources")]
    )
]
#else
let targets: [Target] = [
    .target(
        name: "Blocks",
        dependencies: []
    ),
    .testTarget(
        name: "BlocksTests",
        dependencies: ["Blocks"],
        resources: [.process("Resources")]
    ),
    .target(
        name: "ObjectiveBlocks",
        dependencies: [],
        publicHeadersPath: "public"
    )
]
#endif

let package = Package(
    name: "swift-blocks",
    platforms: [
        .macOS(.v10_15), // Limiting factor: XCTest's fulfillment
        .iOS(.v13), // Limiting factor: XCTest's fulfillment
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: products,
    dependencies: [],
    targets: targets
)
