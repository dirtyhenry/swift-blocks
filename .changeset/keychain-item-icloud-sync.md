---
"swift-blocks": minor
---

Add a `storage` option to `GenericPasswordKeychainItem` to opt into iCloud
Keychain synchronization (`.localOnly` remains the default), and document the
security trade-offs between the two modes. The `.iCloud` mode is unavailable on
tvOS, which never syncs app keychain items.
