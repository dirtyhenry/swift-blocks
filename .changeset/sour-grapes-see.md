---
"swift-blocks": patch
---

Add `@discardableResult` to `shell` function

This will help silence warnings in current usage of the `shell` function:

```sh
- warning: result of call to 'shell' is unused
```
