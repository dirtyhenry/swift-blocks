---
"swift-blocks": minor
---

Implement `WatchPairingUtil` for Swift 6. The app activates the Watch
Connectivity session one time, at launch; the utility only observes it. Read
`isPaired` for an immediate answer, or await `isPaired(timeoutAfter:)` to wait
for the activation. Each call observes the activation state on its own, so
concurrent calls, timeouts and cancellations cannot resume a continuation twice.
Call `activationDidComplete(with:)` from the session delegate to make the
callers that wait throw `WatchActivationFailedError` when the activation fails. When the session has no delegate, `isPaired(timeoutAfter:)` throws
`WatchSessionHasNoDelegateError` immediately instead of a timeout.
