---
"swift-blocks": patch
---

Conform `URLRequestHeaderItem` to `Sendable` so it can safely cross actor boundaries under strict concurrency checking.
