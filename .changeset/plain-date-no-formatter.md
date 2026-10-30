---
"swift-blocks": patch
---

`PlainDate` parses and formats dates without an `ISO8601DateFormatter`. This makes `description`, `yearWeek`, decoding and encoding faster.
