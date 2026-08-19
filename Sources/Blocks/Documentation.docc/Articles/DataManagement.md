# Data Management

## Storing secrets in the keychain

``GenericPasswordKeychainItem`` manages _generic password_ keychain items. Each
item can be stored in one of two modes, chosen at initialization via
``GenericPasswordKeychainItem/Storage``.

### Choosing between local-only and iCloud storage

**Local-only** (`.localOnly`, the default): the secret never leaves the device.
This is the strongest confinement — to obtain the secret, an attacker needs
access to this physical device (or a backup of it). The downside is
availability: the secret is not accessible from the user's other devices, and
it is gone for good if the device is lost, wiped, or replaced.

**iCloud** (`.iCloud`): iCloud Keychain syncs the secret with end-to-end
encryption — Apple cannot read it, and it is protected by the user's device
passcodes. The upside is that the secret is available on all of the user's
devices and survives the loss of any single one. The downside is a wider
exposure surface: the secret now lives on every synced device, so its safety is
that of the *weakest* enrolled device, and of the Apple ID itself — an account
takeover combined with the enrollment of a new device through recovery flows
would expose it.

As a rule of thumb, default to `.localOnly` for device-scoped secrets (for
example, per-device tokens), and choose `.iCloud` for user-scoped secrets the
user would otherwise have to re-enter on each of their devices.

`.iCloud` is unavailable on tvOS: tvOS never syncs app keychain items in either
direction — items stored there never leave the device, and items synced from
other devices never appear there — so `.localOnly` is the only mode on that
platform.

Items are stored with the default accessibility
(`kSecAttrAccessibleWhenUnlocked`), which is compatible with both modes.

### Migrating an existing local item to iCloud

The keychain treats a local item and a synchronizable item with the same label
and account as two distinct items, and each ``GenericPasswordKeychainItem``
instance only ever sees the item matching its own storage mode. Migration is
therefore two instances with the same label and account:

```swift
let local = GenericPasswordKeychainItem(label: "MyApp", account: "api-token")
let synced = GenericPasswordKeychainItem(label: "MyApp", account: "api-token", storage: .iCloud)

if let secret = try local.read() {
    try synced.write(secret)
    try local.delete()
}
```

Read the local copy, write it as a synced item, then delete the local copy so
the two variants cannot drift apart. The reverse direction works the same way
if a user opts back out of syncing.

## Topics

- ``GenericPasswordKeychainItem``
- ``DataFormatter``
- ``SecurityError``
