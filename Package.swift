// swift-tools-version:5.7

// 📜 https://github.com/apple/swift-package-manager/blob/main/Documentation/PackageDescription.md
import PackageDescription

let package = Package(
    name: "swift-blocks",
    platforms: [
        .macOS(.v10_15), // Limiting factor: XCTest's fulfillment
        .iOS(.v13), // Limiting factor: XCTest's fulfillment
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "Blocks",
            targets: ["Blocks"]
        )
    ],
    dependencies: [],
    targets: [
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
)
