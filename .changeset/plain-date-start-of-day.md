---
"swift-blocks": patch
---

`PlainDate(date:calendar:)` keeps the start of the day. Two plain dates on the same day are now equal, and ranges stop at the correct day.
