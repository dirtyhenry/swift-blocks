---
"swift-blocks": minor
---

Iterate on `CLIUtils.shell` command.

⚠️ The signature now throws:

```diff
-static func shell(_ command: String) -> String
+static func shell(_ command: String) throws -> String
```