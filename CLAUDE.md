# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Development Commands

### Building

- `make build` - Build the Swift package for macOS
- `make build-ios` - Build for iOS platforms
- `swift build -c release` - Build release configuration
- `make cli` - Build the BlocksCLI command-line tool

### Testing

- `make test` - Run tests with formatted output
- `make test-debug` - Run tests with verbose output for debugging
- `make test-ios` - Run tests on iOS simulator
- `swift test --filter [TestName]` - Run specific test

### Code Quality

- `make lint` - Check code style and formatting
- `make format` - Autoformat code using SwiftFormat and SwiftLint

### Documentation

- `make docs` - Generate documentation archive
- `make serve-docs` - Serve documentation locally

### Versioning

- Uses [@changesets/cli](https://github.com/changesets/changesets) for version
  management
- Create changeset files directly in `.changeset/` directory (interactive
  `yarn changeset` may not work in Claude Code)
- Changeset file format: `.changeset/description-slug.md` with frontmatter
  specifying package and change type

Example changeset file:

```markdown
---
"swift-blocks": patch
---

Description of the change
```

## Architecture Overview

This is a Swift package library providing reusable building blocks with zero
external dependencies. The codebase follows a modular architecture with clear
separation of concerns.

### Core Components

**Blocks** (Sources/Blocks/) The main library providing utilities across several
domains:

- **Transport Layer** - Protocol-based networking abstraction with decorators
  for logging, retry, and status code checking. Key protocol: `Transport`
- **PlainDate** - Type for handling dates without time components, supporting
  ranges and arithmetic
- **Security** - Keychain management, PKCE implementation for OAuth flows
- **Web Protocols** - JSON Feed, Sitemap, OpenGraph, Front Matter parsing
- **Calendar** - iCalendar format support
- **UI Components** - SwiftUI components like TaskStateButton, PlainDatePicker

**ObjectiveBlocks** (Sources/ObjectiveBlocks/) Legacy Objective-C compatible
utilities for iOS/macOS development.

### Transport Pattern

The Transport system uses a decorator pattern for composable request handling:

```swift
URLSession → LoggingTransport → RetryTransport → StatusCodeCheckingTransport
```

Each transport wrapper adds specific behavior while conforming to the same
`Transport` protocol.

### Platform Support

- Primary platforms: macOS 10.15+, iOS 13+, tvOS 15+, watchOS 8+
- Linux support with conditional compilation for platform-specific features
- Uses `#if os(Linux)` and `#if canImport()` for cross-platform compatibility

### Testing Strategy

- Unit tests in Tests/BlocksTests/ with XCTest
- Test resources in Tests/BlocksTests/Resources/
- Example apps for integration testing (BlocksApp, BlocksAppTCA)
- CI runs on macOS, iOS, and Linux via GitHub Actions

## Key Development Patterns

- **Protocol-Oriented Design**: Core functionality exposed through protocols
  (Transport, Endpoint)
- **Async/Await**: Modern concurrency with `@available(iOS 15.0, macOS 12.0, *)`
  checks
- **No External Dependencies**: The Blocks library has zero external
  dependencies
- **Conditional Compilation**: Platform-specific code isolated with compiler
  directives
