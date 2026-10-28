#if os(iOS)
import UIKit
import WatchConnectivity

/// Tells whether an Apple Watch is paired with this iPhone.
///
/// `WCSession.isPaired` is valid only after the host app activates the default session.
/// This utility does not activate the session and does not set its delegate: those are the
/// responsibility of the app. Set a delegate on `WCSession.default` and call `activate()` one time,
/// at launch. See <doc:WatchPairing> for a minimal delegate.
///
/// Then read ``isPaired`` for an immediate answer, or await ``isPaired(timeoutAfter:)`` to wait for
/// the activation. Each call observes the session on its own, so concurrent calls do not interfere
/// with each other.
///
/// Watch Connectivity tells only the delegate when an activation fails. To report the failure to
/// the callers that wait, call ``activationDidComplete(with:)`` from
/// `session(_:activationDidCompleteWith:error:)`.
@available(iOS 14.0, *)
public enum WatchPairingUtil {
    /// Whether a watch is paired. `nil` while the session is not activated.
    ///
    /// `false` on devices that do not support Watch Connectivity, such as iPad.
    public static var isPaired: Bool? {
        guard WCSession.isSupported() else { return false }
        guard case let .activated(isPaired) = WCSession.default.pairingActivation else { return nil }
        return isPaired
    }

    /// Waits for the session activation, at most `maxDuration` seconds, and returns whether a watch is paired.
    ///
    /// Returns immediately when the session is already activated. Returns `false` on devices that do
    /// not support Watch Connectivity.
    ///
    /// - Throws: ``WatchSessionHasNoDelegateError`` immediately when the session is not activated and
    ///   has no delegate, ``WatchActivationFailedError`` when the activation fails and the app reported it with
    ///   ``activationDidComplete(with:)``, ``WatchActivationTimedOutError`` after `maxDuration`,
    ///   `CancellationError` when the calling task is cancelled.
    public static func isPaired(
        timeoutAfter maxDuration: TimeInterval
    ) async throws -> Bool {
        guard WCSession.isSupported() else { return false }
        let session = WCSession.default
        // The app sets the delegate before it calls `activate()`. Without a delegate, no activation
        // is in progress, and the wait could only time out.
        if session.activationState == .notActivated, session.delegate == nil {
            throw WatchSessionHasNoDelegateError()
        }
        return try await ActivationWait.isPaired(of: WCSession.default, timeoutAfter: maxDuration)
    }

    /// Reports the result of a session activation to the callers that wait.
    ///
    /// Call this function from `session(_:activationDidCompleteWith:error:)` in the delegate of the
    /// app. When `error` is not `nil`, the callers of ``isPaired(timeoutAfter:)`` throw
    /// ``WatchActivationFailedError`` immediately. They do not wait for the timeout.
    public static func activationDidComplete(with error: (any Error)?) {
        lastActivationError.set(error)
        NotificationCenter.default.post(name: activationDidCompleteNotification, object: nil)
    }
}

/// The error of the last activation, `nil` when it succeeded or when the app did not report it.
private let lastActivationError = LockedError()

private let activationDidCompleteNotification = Notification.Name("WatchPairingUtil.activationDidComplete")

/// An error that any thread can read and write.
private final class LockedError: @unchecked Sendable {
    private let lock = NSLock()
    private var error: (any Error)?

    func set(_ error: (any Error)?) {
        lock.lock()
        defer { lock.unlock() }
        self.error = error
    }

    func get() -> (any Error)? {
        lock.lock()
        defer { lock.unlock() }
        return error
    }
}

extension WCSession: PairingSession {
    var pairingActivation: PairingActivation {
        if activationState == .activated {
            return .activated(isPaired: isPaired)
        }
        if let error = lastActivationError.get() {
            return .failed(error)
        }
        return .pending
    }

    func observeActivation(
        _ handler: @escaping @Sendable (PairingActivation) -> Void
    ) -> ActivationObservation {
        // A failed activation does not change `activationState`, so the app reports it through
        // `WatchPairingUtil.activationDidComplete(with:)`, which posts this notification. The block
        // reads `WCSession.default` because a `@Sendable` block cannot capture the session.
        let token = NotificationCenter.default.addObserver(
            forName: activationDidCompleteNotification,
            object: nil,
            queue: nil
        ) { _ in
            handler(WCSession.default.pairingActivation)
        }
        // `activationState` is documented as KVO-observable. `.initial` delivers the current state
        // synchronously, so no activation can slip between a check and the observation.
        let observation = observe(\.activationState, options: [.initial, .new]) { session, _ in
            handler(session.pairingActivation)
        }
        return ActivationObservation {
            observation.invalidate()
            NotificationCenter.default.removeObserver(token)
        }
    }
}

@available(iOS 14.0, *)
public extension UIDevice {
    /// Waits for the Watch Connectivity session activation and returns whether a watch is paired.
    ///
    /// See ``WatchPairingUtil/isPaired(timeoutAfter:)``.
    func isPairedWithWatch(
        timeoutAfter maxDuration: TimeInterval
    ) async throws -> Bool {
        try await WatchPairingUtil.isPaired(timeoutAfter: maxDuration)
    }
}
#endif
