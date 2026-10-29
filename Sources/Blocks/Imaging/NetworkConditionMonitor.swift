#if canImport(Network)

import Foundation
import Network

/// The quality of the current network connection.
public enum NetworkCondition: Sendable, Equatable {
    /// A Wi-Fi or wired connection that is not expensive and not constrained.
    case excellent
    /// A cellular connection, or a connection of an other type.
    case good
    /// An expensive or constrained connection, for example a personal hotspot or Low Data Mode.
    case poor
    /// No connection.
    case offline
}

/// Monitors the network with `NWPathMonitor` and gives the changes as an `AsyncStream`.
///
/// Call ``start()`` one time. After you call ``stop()``, you cannot start the monitor again.
/// Make a new monitor instead.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public final class NetworkConditionMonitor: Sendable {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let state = State()

    private final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var currentCondition: NetworkCondition = .offline
        private var continuations: [UUID: AsyncStream<NetworkCondition>.Continuation] = [:]
        private var isFinished = false

        var condition: NetworkCondition {
            lock.lock()
            defer { lock.unlock() }
            return currentCondition
        }

        /// The yields occur in the lock, so that a new subscriber cannot get the current condition
        /// after a more recent one. `finish()` occurs out of the lock, because it calls
        /// `onTermination` synchronously.
        func update(_ condition: NetworkCondition) {
            lock.lock()
            defer { lock.unlock() }
            guard condition != currentCondition else { return }
            currentCondition = condition
            for continuation in continuations.values {
                continuation.yield(condition)
            }
        }

        func add(_ continuation: AsyncStream<NetworkCondition>.Continuation, id: UUID) {
            lock.lock()
            continuation.yield(currentCondition)
            guard !isFinished else {
                lock.unlock()
                continuation.finish()
                return
            }
            continuations[id] = continuation
            lock.unlock()
        }

        func remove(id: UUID) {
            lock.lock()
            defer { lock.unlock() }
            continuations[id] = nil
        }

        func finish() {
            lock.lock()
            isFinished = true
            let subscribers = Array(continuations.values)
            continuations.removeAll()
            lock.unlock()

            for continuation in subscribers {
                continuation.finish()
            }
        }
    }

    public init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "com.blocks.network-condition-monitor")
    }

    deinit {
        monitor.cancel()
        state.finish()
    }

    /// Starts the monitor.
    public func start() {
        let state = state
        monitor.pathUpdateHandler = { path in
            state.update(Self.mapPathToCondition(path))
        }
        monitor.start(queue: queue)
    }

    /// Stops the monitor and finishes all the streams.
    public func stop() {
        monitor.cancel()
        state.finish()
    }

    /// The current network condition.
    ///
    /// The value is ``NetworkCondition/offline`` until the monitor gets the first network path.
    public var currentCondition: NetworkCondition {
        state.condition
    }

    /// An async stream of the network conditions.
    ///
    /// The stream first gives the current condition. Then it gives each change.
    /// Each access to this property gives a new stream, so many subscribers can use it at the same time.
    public var conditions: AsyncStream<NetworkCondition> {
        let state = state
        let id = UUID()
        return AsyncStream { continuation in
            continuation.onTermination = { _ in
                state.remove(id: id)
            }
            state.add(continuation, id: id)
        }
    }

    /// Maps an `NWPath` to a `NetworkCondition`.
    ///
    /// Exposed as internal for testing.
    static func mapPathToCondition(_ path: NWPath) -> NetworkCondition {
        guard path.status == .satisfied else {
            return .offline
        }

        if path.isExpensive || path.isConstrained {
            return .poor
        }

        if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
            return .excellent
        }

        return .good
    }
}

#endif
