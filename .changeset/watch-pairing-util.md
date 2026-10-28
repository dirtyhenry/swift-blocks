---
"swift-blocks": minor
---

Implement `WatchPairingUtil` for Swift 6. Activate the session one time with
`activateSession()`, read `isPaired` for an immediate answer, or await
`isPaired(timeoutAfter:)` to wait for the activation. Each call observes the
activation state on its own, so concurrent calls, timeouts and cancellations
cannot resume a continuation twice or activate the session twice.
