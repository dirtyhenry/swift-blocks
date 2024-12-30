<h1 align="center">
    <img 
        src="https://raw.githubusercontent.com/dirtyhenry/swift-blocks/main/swift-blocks.jpg"
        alt="swift-blocks logo">
</h1>

# 🧱 Blocks

[![Build macOS CI state badge](https://github.com/dirtyhenry/swift-blocks/workflows/Build%20macOS/badge.svg)](https://github.com/dirtyhenry/swift-blocks/actions?query=workflow:%22Build+macOS%22++)
[![Swift versions compatibility badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdirtyhenry%2Fswift-blocks%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/dirtyhenry/swift-blocks)
[![Platforms compatibility badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdirtyhenry%2Fswift-blocks%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dirtyhenry/swift-blocks)

A collection of my Swift building blocks.

This repository contains:

- `Blocks`: a **dependency-free** Swift package with some utilities to deal with
  networking, API management, web protocols, etc.;

And the following examples executables/apps:

- `BlocksCLI`: a command-line interface for basic proof-of-concepts;
- `BlocksApp`: a basic App with no other dependencies than `Blocks` and
  Apple-provided 1st-party frameworks.

> [!TIP]
>
> 🏘️ For a similar package that builds on a curated set of dependencies (such as
> TCA, Yams, or Swift Argument Parser), watch out my [Hoods][hoods] package.

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
        from: "0.6.0"
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

[hoods]: https://github.com/dirtyhenry/swift-hoods
