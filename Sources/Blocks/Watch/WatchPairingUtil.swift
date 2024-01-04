#if os(iOS)
import Combine
import os
import SwiftUI
import WatchConnectivity

@available(iOS 14.0, *)
let logger = Logger(subsystem: "net.mickf.Blocks", category: "Watch")

@available(iOS 14.0, *)
/// A utility singleton that can detect if a watch is paired to a device with ease.
public class WatchPairingUtil: NSObject {
    struct TimedOutError: Error, Equatable {}

    static var shared = WatchPairingUtil()

    override private init() {
        logger.debug("Creating an instance of WatchPairingUtil.")
        super.init()
    }

    private var activationContinuation: CheckedContinuation<Bool, Never>?

    public func isPaired(
        timeoutAfter maxDuration: TimeInterval
    ) async throws -> Bool {
        logger.debug("Called isPaired")
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await self.activateSession()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(maxDuration * 1_000_000_000))
                try Task.checkCancellation()
                // We’ve reached the timeout.
                logger.error("Throwing timeout")
                throw TimedOutError()
            }

            // First finished child task wins, cancel the other task.
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func activateSession() async throws -> Bool {
        let session = WCSession.default
        session.delegate = self

        // A cancellation handler is required here otherwise, cancellation won't happen and
        // `withThrowingTaskGroup` will hang.
        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { continuation in
                activationContinuation = continuation
                session.activate()
            }
        }, onCancel: {
            // Since the task was cancelled, the value that is returned won't play a role
            activationContinuation?.resume(returning: false)
            // But for safety sake, let's remove the reference to prevent another call to `resume`.
            activationContinuation = nil
        })
    }
}

@available(iOS 14.0, *)
extension WatchPairingUtil: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith _: WCSessionActivationState, error: Error?) {
        logger.debug("Session activation did complete")

        if let error {
            logger.error("Session activation did complete with error: \(error.localizedDescription, privacy: .public)")
        }

        activationContinuation?.resume(with: .success(session.isPaired))
    }

    public func sessionDidBecomeInactive(_: WCSession) {
        // Do nothing
    }

    public func sessionDidDeactivate(_: WCSession) {
        // Do nothing
    }
}

@available(iOS 14.0, *)
public extension UIDevice {
    func isPairedWithWatch(
        timeoutAfter maxDuration: TimeInterval
    ) async throws -> Bool {
        try await WatchPairingUtil.shared.isPaired(timeoutAfter: maxDuration)
    }
}
#endif
