#if os(iOS)
import Blocks
import OSLog
import WatchConnectivity

/// The app owns the Watch Connectivity session. `Blocks` only observes it.
///
/// Call ``activate()`` one time, at launch. This is the minimal delegate for an app that does not
/// talk to a watch app and only wants to know whether a watch is paired.
final class WatchSessionDelegate: NSObject, WCSessionDelegate, Sendable {
    static let shared = WatchSessionDelegate()

    private let logger = Logger(subsystem: "net.mickf.blocks", category: "Watch")

    nonisolated func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // The delegate methods run on a background serial queue.

    nonisolated func session(_: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("Watch session activation failed (state \(state.rawValue)): \(error.localizedDescription)")
        } else {
            logger.debug("Watch session activated (state \(state.rawValue))")
        }
        // Without this call, a failed activation looks like a timeout to the callers that wait.
        WatchPairingUtil.activationDidComplete(with: error)
    }

    nonisolated func sessionDidBecomeInactive(_: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // After the user switches to another watch, the app must activate the session again.
        session.activate()
    }
}
#endif
