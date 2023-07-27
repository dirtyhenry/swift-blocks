# 🧱 Blocks

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
