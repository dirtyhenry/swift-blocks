---
"swift-blocks": patch
---

Fix `Sendable` conformance for `RetryTransport` and
`StatusCodeCheckingTransport`

- Added `@Sendable` attributes to closure parameters and properties in
  `RetryTransport`
- Added `@Sendable` attributes to closure parameters and properties in
  `StatusCodeCheckingTransport`
- Updated `RetryTransport.max(of:)` to return a `@Sendable` closure
- Both transport classes now properly conform to `Sendable` protocol
  requirements
