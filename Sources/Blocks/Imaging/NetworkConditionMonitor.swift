#if canImport(Network)

import Foundation
import Network

/// Represents the quality of the current network connection.
public enum NetworkCondition: Sendable, Equatable {
    case excellent
    case good
    case poor
    case offline
}

/// Monitors network conditions using `NWPathMonitor` and exposes changes
/// as an `AsyncStream`.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public final class NetworkConditionMonitor: Sendable {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let state: State

    private actor State {
        var currentCondition: NetworkCondition = .offline
        var continuation: AsyncStream<NetworkCondition>.Continuation?

        func update(_ condition: NetworkCondition) {
            guard condition != currentCondition else { return }
            currentCondition = condition
            continuation?.yield(condition)
        }

        func getCondition() -> NetworkCondition {
            currentCondition
        }

        func setContinuation(_ continuation: AsyncStream<NetworkCondition>.Continuation) {
            self.continuation = continuation
        }

        func finish() {
            continuation?.finish()
            continuation = nil
        }
    }

    public init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "com.blocks.network-condition-monitor")
        state = State()
    }

    /// Starts monitoring network conditions.
    public func start() {
        let state = state
        monitor.pathUpdateHandler = { path in
            let condition = Self.mapPathToCondition(path)
            Task { await state.update(condition) }
        }
        monitor.start(queue: queue)
    }

    /// Stops monitoring network conditions.
    public func stop() {
        monitor.cancel()
        Task { await state.finish() }
    }

    /// The current network condition.
    public var currentCondition: NetworkCondition {
        get async { await state.getCondition() }
    }

    /// An async stream of network condition changes.
    public var conditions: AsyncStream<NetworkCondition> {
        let state = state
        return AsyncStream { continuation in
            Task { await state.setContinuation(continuation) }
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

        if path.usesInterfaceType(.cellular) {
            return .good
        }

        return .good
    }
}

#endif
