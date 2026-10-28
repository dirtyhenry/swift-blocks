#if os(iOS)
import OSLog
import UIKit
import WatchConnectivity

@available(iOS 14.0, *)
let logger = Logger(subsystem: "net.mickf.Blocks", category: "Watch")

/// A utility that tells whether an Apple Watch is paired with this iPhone.
///
/// Watch Connectivity reports the pairing only after the default session is activated. Activate the
/// session one time, at launch:
///
/// - If your app has no `WCSessionDelegate`, call ``activateSession()`` from the app delegate.
/// - If your app has its own delegate, activate the session as you already do. This utility only
///   observes the activation state; it does not need to be the delegate.
///
/// Then read ``isPaired`` for an immediate answer, or await ``isPaired(timeoutAfter:)`` to wait for
/// the activation. The utility holds no state, so concurrent calls do not interfere with each other.
@available(iOS 14.0, *)
public final class WatchPairingUtil: NSObject, Sendable {
    public static let shared = WatchPairingUtil()

    override private init() {
        super.init()
    }

    /// Sets ``shared`` as the delegate of the default session and activates it.
    ///
    /// Call this one time, at launch. Do not call it when your app has its own `WCSessionDelegate`.
    public func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Whether a watch is paired. `nil` while the session is not activated.
    public var isPaired: Bool? {
        guard WCSession.isSupported() else { return false }
        return WCSession.default.pairingState
    }

    /// Waits for the session activation, at most `maxDuration` seconds, and returns whether a watch is paired.
    ///
    /// Returns immediately when the session is already activated.
    ///
    /// - Throws: ``WatchActivationTimedOutError`` after `maxDuration`, `CancellationError` when the
    ///   calling task is cancelled.
    public func isPaired(
        timeoutAfter maxDuration: TimeInterval
    ) async throws -> Bool {
        guard WCSession.isSupported() else { return false }
        return try await ActivationWait.isPaired(of: WCSession.default, timeoutAfter: maxDuration)
    }
}

@available(iOS 14.0, *)
extension WatchPairingUtil: WCSessionDelegate {
    // All delegate methods run on the Watch Connectivity background serial queue.

    public func session(
        _: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            logger.error(
                "Session activation failed (state \(state.rawValue)): \(error.localizedDescription, privacy: .public)"
            )
        } else {
            logger.debug("Session activation did complete (state \(state.rawValue))")
        }
    }

    public func sessionDidBecomeInactive(_: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        // Apple: after a watch switch, the iOS app must activate the session again.
        session.activate()
    }
}

extension WCSession: PairingSession {
    /// `nil` while the session is not activated.
    var pairingState: Bool? {
        activationState == .activated ? isPaired : nil
    }

    func observeActivation(
        _ handler: @escaping @Sendable (_ isPaired: Bool?) -> Void
    ) -> ActivationObservation {
        // `activationState` is documented as KVO-observable. `.initial` delivers the current state
        // synchronously, so no activation can slip between a check and the observation.
        let observation = observe(\.activationState, options: [.initial, .new]) { session, _ in
            handler(session.pairingState)
        }
        return ActivationObservation(invalidate: observation.invalidate)
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
        try await WatchPairingUtil.shared.isPaired(timeoutAfter: maxDuration)
    }
}
#endif
