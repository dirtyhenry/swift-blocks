---
"swift-blocks": minor
---

Add `sanitizedFilename(maxLength:fallback:)` to `StringProtocol`. It makes a
safe filename from a title for macOS and Obsidian. Unlike `slugify()`, it keeps
accents, emoji and spaces.
