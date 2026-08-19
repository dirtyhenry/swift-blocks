---
"swift-blocks": minor
---

Add a `storage` option to `GenericPasswordKeychainItem` to opt into iCloud
Keychain synchronization (`.localOnly` remains the default), and document the
security tradeoffs between the two modes.
