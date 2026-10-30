---
"swift-blocks": patch
---

`PlainDate(from:calendar:)` returns `nil` for a day that does not exist, such as `2022-02-30`.
