// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlocksCLI",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13) // CLI not intended to work on iOS but Xcode will fail without this.
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(name: "Blocks", path: "../../")
    ],
    targets: [
        .executableTarget(name: "BlocksCLI", dependencies: [
            .product(name: "Blocks", package: "Blocks"),
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]),
        .testTarget(
            name: "BlocksCLITests",
            dependencies: ["BlocksCLI"],
            resources: [.process("Resources")]
        )
    ]
)
