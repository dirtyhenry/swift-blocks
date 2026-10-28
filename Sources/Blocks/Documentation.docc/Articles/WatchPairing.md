# Detect a paired Apple Watch

Find out whether an Apple Watch is paired with the iPhone.

## Overview

`WCSession.default.isPaired` tells whether a watch is paired. The value is valid only after the
session is activated.

The app owns the session. `Blocks` does not activate the session and does not set its delegate.
`WatchPairingUtil` only observes the activation state and reads `isPaired`.

### Activate the session in the app

Set a delegate on the default session and activate it one time, at launch. This is the minimal
delegate for an app that does not talk to a watch app:

```swift
import Blocks
import WatchConnectivity

final class WatchSessionDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchSessionDelegate()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error: Error?) {
        // Report a failed activation to the callers that wait.
        WatchPairingUtil.activationDidComplete(with: error)
    }

    func sessionDidBecomeInactive(_: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // After the user switches to another watch, the app must activate the session again.
        session.activate()
    }
}
```

Call `WatchSessionDelegate.shared.activate()` from `application(_:didFinishLaunchingWithOptions:)`
or from the `init` of your `App`.

### Find out if a watch is paired

For an immediate answer, read `WatchPairingUtil.isPaired`. The value is `nil` while the session
is not activated:

```swift
if let isPaired = WatchPairingUtil.isPaired {
    // Use `isPaired`.
}
```

To wait for the activation, await `WatchPairingUtil.isPaired(timeoutAfter:)`. It returns
immediately when the session is activated. It throws these errors:

- ``WatchSessionHasNoDelegateError`` immediately, when the session is not activated and has no
  delegate. Make sure that the app activates the session at launch.
- ``WatchActivationFailedError`` when the activation fails.
- ``WatchActivationTimedOutError`` when the activation does not complete in time.

```swift
let isPaired = try await UIDevice.current.isPairedWithWatch(timeoutAfter: 3)
```

Do not call `WCSession.default.activate()` from the code that reads `isPaired`. A second call
while an activation is pending can crash the app.

> Note: `WatchPairingUtil` is available on iOS only, so this documentation, built for macOS, does not link to its symbols.
