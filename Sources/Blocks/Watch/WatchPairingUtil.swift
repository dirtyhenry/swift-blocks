#if os(iOS)
import Combine
import OSLog
import SwiftUI
import WatchConnectivity

@available(iOS 14.0, *)
let logger = Logger(subsystem: "net.mickf.Blocks", category: "Watch")

/// A utility singleton that can detect if a watch is paired to a device with ease.
@available(iOS 14.0, *)
public final class WatchPairingUtil: NSObject, Sendable {
    static let shared = WatchPairingUtil()

    override private init() {
        logger.debug("Creating an instance of WatchPairingUtil.")
        super.init()
    }

    public func isPaired(
        timeoutAfter _: TimeInterval
    ) async throws -> Bool {
        fatalError("FIXME: Add an implementation working with Swift 6.")
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
