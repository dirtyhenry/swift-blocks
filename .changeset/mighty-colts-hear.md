---
"swift-blocks": patch
---

Stop escaping slashes on `JSON` functions.

Output examples:

```diff
-foo\/bar
+foo/bar
```
