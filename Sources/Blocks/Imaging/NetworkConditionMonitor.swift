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
        var continuations: [UUID: AsyncStream<NetworkCondition>.Continuation] = [:]

        func update(_ condition: NetworkCondition) {
            guard condition != currentCondition else { return }
            currentCondition = condition
            for continuation in continuations.values {
                continuation.yield(condition)
            }
        }

        func getCondition() -> NetworkCondition {
            currentCondition
        }

        func addContinuation(_ continuation: AsyncStream<NetworkCondition>.Continuation, id: UUID) {
            continuations[id] = continuation
        }

        func removeContinuation(id: UUID) {
            continuations[id]?.finish()
            continuations[id] = nil
        }

        func finish() {
            for continuation in continuations.values {
                continuation.finish()
            }
            continuations.removeAll()
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
    ///
    /// Multiple subscribers can consume this stream concurrently;
    /// each receives its own independent stream of updates.
    public var conditions: AsyncStream<NetworkCondition> {
        let state = state
        let id = UUID()
        return AsyncStream { continuation in
            continuation.onTermination = { _ in
                Task { await state.removeContinuation(id: id) }
            }
            Task { await state.addContinuation(continuation, id: id) }
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
