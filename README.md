# 🧱 Blocks

## Installation

```swift
let package = Package(
    …
    dependencies: [
        …
        .package(url: "https://github.com/dirtyhenry/blocks", branch: "main")
    ],
    targets: [
        …
        .Target(name: "…", dependencies: [
            …
            .product(name: "Blocks", package: "Blocks")
        ])
    ]
)
```

## Usage

The package is documented via
[DocC on Vercel](https://blocks-git-vercel-dirtyhenry.vercel.app/documentation/blocks).

## License

[MIT](https://choosealicense.com/licenses/mit/)
