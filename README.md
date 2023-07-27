# 🧱 Blocks

A collection of my Swift building blocks.

This repository contains:

- `Blocks`: a **dependency-free** Swift library for my development needs;

And the following examples executables/apps:

- `BlocksCLI`: a command-line interface for basic proof-of-concepts;
- `BlocksApp`: a basic App with no other dependencies than `Blocks` and Apple-provided 1st-party frameworks;
- `BlocksAppTCA`: a basic App using `Blocks` within an app designed using [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

## Usage

```swift
import Blocks
```

## Installation

Swift Package Manager is recommended:

```swift
dependencies: [
    .package(
        url: "https://github.com/dirtyhenry/swift-blocks",
        from: "0.1.0"
    ),
]
```

Next, add `Blocks` as a dependency of your test target:

```swift
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "Blocks", package: "swift-blocks")
    ])
]
```

## License

[MIT](https://choosealicense.com/licenses/mit/)
