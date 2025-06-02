---
"swift-blocks": minor
---

Add Craft-style URL generation for PlainDate

Example:

```swift
let date: PlainDate = "2025-06-02"
let url = try date.craftURL()
// url is day://2025.06.02
```
