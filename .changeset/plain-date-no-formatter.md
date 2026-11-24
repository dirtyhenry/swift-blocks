---
"swift-blocks": patch
---

`PlainDate` parses and formats ISO 8601 strings with `Calendar`, not with `ISO8601DateFormatter`. `PlainDate(from:)` now accepts only the `YYYY-MM-DD` format. `description`, `yearWeek`, decoding and encoding no longer make a formatter for each call, which makes them about 150 times faster.
