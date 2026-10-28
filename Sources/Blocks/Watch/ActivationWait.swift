import Foundation

/// The part of a Watch Connectivity session that `ActivationWait` needs.
///
/// `WCSession` conforms to this protocol on iOS. Tests use a fake, so the wait logic runs on every platform.
protocol PairingSession: AnyObject {
    /// Calls `handler` now and each time the activation state changes.
    ///
    /// The handler can run on any thread.
    func observeActivation(
        _ handler: @escaping @Sendable (PairingActivation) -> Void
    ) -> ActivationObservation
}

/// The activation state of a session, as `ActivationWait` sees it.
enum PairingActivation: Sendable {
    /// The session is not activated.
    case pending
    /// The session is activated.
    case activated(isPaired: Bool)
    /// An activation failed. The session delivers this value only once, when the activation fails.
    case failed(any Error)
}

/// A token that stops an activation observation.
struct ActivationObservation {
    let invalidate: () -> Void
}

/// An error thrown when the session does not activate in time.
public struct WatchActivationTimedOutError: Error, Equatable {
    public init() {}
}

/// An error thrown when the app did not set a delegate on the session.
///
/// Without a delegate, the app cannot activate the session, so a wait can only time out.
public struct WatchSessionHasNoDelegateError: Error, Equatable {
    public init() {}
}

/// An error thrown when the session activation fails.
public struct WatchActivationFailedError: Error {
    /// The error that the session gave to `session(_:activationDidCompleteWith:error:)`.
    public let underlyingError: any Error

    public init(underlyingError: any Error) {
        self.underlyingError = underlyingError
    }
}

enum ActivationWait {
    private enum Outcome: Sendable {
        case paired(Bool)
        case failed(any Error)
        case timedOut
        case cancelled
    }

    /// Waits for `session` to be activated and returns whether a watch is paired.
    ///
    /// Three events race to finish the wait: the end of the activation (success or failure), the
    /// timeout and the cancellation of the calling task. A ``OneShot`` makes sure that exactly one of them resumes the caller.
    static func isPaired(
        of session: some PairingSession,
        timeoutAfter maxDuration: TimeInterval
    ) async throws -> Bool {
        let slot = OneShot<Outcome>()

        let outcome = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                // `put` fails only when the cancellation handler already ran, which happens when
                // the task was cancelled before this operation started. The handler does not run again.
                guard slot.put(continuation) else {
                    return continuation.resume(returning: .cancelled)
                }

                // The first delivery is synchronous: an activated session resumes the caller right here.
                let observation = session.observeActivation { activation in
                    switch activation {
                    case .pending:
                        return
                    case let .activated(isPaired):
                        slot.take()?.resume(returning: .paired(isPaired))
                    case let .failed(error):
                        slot.take()?.resume(returning: .failed(error))
                    }
                }
                slot.onTake(observation.invalidate)

                let timeout = Task {
                    try? await Task.sleep(nanoseconds: nanoseconds(from: maxDuration))
                    slot.take()?.resume(returning: .timedOut)
                }
                slot.onTake(timeout.cancel)
            }
        } onCancel: {
            slot.take()?.resume(returning: .cancelled)
        }

        switch outcome {
        case let .paired(isPaired):
            return isPaired
        case let .failed(error):
            throw WatchActivationFailedError(underlyingError: error)
        case .timedOut:
            throw WatchActivationTimedOutError()
        case .cancelled:
            throw CancellationError()
        }
    }

    /// Converts a duration in seconds to nanoseconds without a trap.
    ///
    /// A negative or NaN duration gives 0. A very large or infinite duration is capped at about 31 years.
    static func nanoseconds(from duration: TimeInterval) -> UInt64 {
        guard duration > 0 else { return 0 }
        return UInt64(min(duration, 1_000_000_000) * 1_000_000_000)
    }
}

/// A continuation that is resumed at most once, from whichever thread gets there first.
///
/// `take()` consumes the continuation and runs the registered cleanups. Callers resume the
/// continuation outside the lock.
private final class OneShot<Value: Sendable>: @unchecked Sendable {
    private enum State {
        case empty
        case waiting(CheckedContinuation<Value, Never>)
        case done
    }

    private let lock = NSLock()
    private var state = State.empty
    private var cleanups: [() -> Void] = []

    /// Stores the continuation. Returns `false` when the slot was already consumed.
    func put(_ continuation: CheckedContinuation<Value, Never>) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard case .empty = state else { return false }
        state = .waiting(continuation)
        return true
    }

    /// Consumes the slot. Returns the continuation on the first call only.
    func take() -> CheckedContinuation<Value, Never>? {
        lock.lock()
        let continuation: CheckedContinuation<Value, Never>? = if case let .waiting(waiting) = state {
            waiting
        } else {
            nil
        }
        state = .done
        let cleanups = cleanups
        self.cleanups = []
        lock.unlock()

        for cleanup in cleanups {
            cleanup()
        }
        return continuation
    }

    /// Runs `cleanup` when the slot is consumed, or now when it already was.
    func onTake(_ cleanup: @escaping () -> Void) {
        lock.lock()
        if case .done = state {
            lock.unlock()
            cleanup()
            return
        }
        cleanups.append(cleanup)
        lock.unlock()
    }
}
