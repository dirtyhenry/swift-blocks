---
"swift-blocks": patch
---

Make `PlainDate` conform to `Sendable`

Remove stored `ISO8601DateFormatter` instance which wasn't `Sendable`-compliant,
and instead create formatter on-demand when needed for string conversion. This
maintains the same functionality while making `PlainDate` thread-safe and
suitable for concurrent contexts.
