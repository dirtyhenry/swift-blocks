---
"swift-blocks": patch
---

`PlainDate` decoding throws a `DecodingError` when the string is not a valid date. It does not stop the app.
