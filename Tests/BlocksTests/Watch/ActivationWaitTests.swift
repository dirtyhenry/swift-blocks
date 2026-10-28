@testable import Blocks
import XCTest

/// A session whose activation the test controls.
private final class FakeSession: PairingSession, @unchecked Sendable {
    private let lock = NSLock()
    private var isPaired: Bool?
    private var handlers: [UUID: @Sendable (Bool?) -> Void] = [:]

    init(isPaired: Bool? = nil) {
        self.isPaired = isPaired
    }

    func activate(isPaired: Bool) {
        lock.lock()
        self.isPaired = isPaired
        let handlers = Array(handlers.values)
        lock.unlock()
        for handler in handlers {
            handler(isPaired)
        }
    }

    var observerCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return handlers.count
    }

    func observeActivation(_ handler: @escaping @Sendable (Bool?) -> Void) -> ActivationObservation {
        let id = UUID()
        lock.lock()
        handlers[id] = handler
        let current = isPaired
        lock.unlock()
        handler(current)
        return ActivationObservation { [weak self] in
            guard let self else { return }
            lock.lock()
            handlers[id] = nil
            lock.unlock()
        }
    }
}

final class ActivationWaitTests: XCTestCase {
    func testReturnsImmediatelyWhenAlreadyActivated() async throws {
        let session = FakeSession(isPaired: true)
        let start = Date()
        let isPaired = try await ActivationWait.isPaired(of: session, timeoutAfter: 1)
        XCTAssertTrue(isPaired)
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.1)
        XCTAssertEqual(session.observerCount, 0)
    }

    func testConcurrentCallersAllGetTheActivationResult() async throws {
        let session = FakeSession()
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            session.activate(isPaired: false)
        }
        let results = try await withThrowingTaskGroup(of: Bool.self) { group in
            for _ in 0 ..< 10 {
                group.addTask { try await ActivationWait.isPaired(of: session, timeoutAfter: 2) }
            }
            return try await group.reduce(into: [Bool]()) { $0.append($1) }
        }
        XCTAssertEqual(results, Array(repeating: false, count: 10))
        XCTAssertEqual(session.observerCount, 0)
    }

    func testThrowsTimedOutWhenActivationNeverCompletes() async {
        let session = FakeSession()
        let start = Date()
        do {
            _ = try await ActivationWait.isPaired(of: session, timeoutAfter: 0.2)
            XCTFail("Expected a timeout")
        } catch is WatchActivationTimedOutError {
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertGreaterThanOrEqual(elapsed, 0.2)
            XCTAssertLessThan(elapsed, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(session.observerCount, 0)
    }

    func testInvalidTimeoutsDoNotTrap() {
        XCTAssertEqual(ActivationWait.nanoseconds(from: -1), 0)
        XCTAssertEqual(ActivationWait.nanoseconds(from: .nan), 0)
        XCTAssertEqual(ActivationWait.nanoseconds(from: 0.5), 500_000_000)
        XCTAssertEqual(ActivationWait.nanoseconds(from: .infinity), 1_000_000_000_000_000_000)
        XCTAssertEqual(ActivationWait.nanoseconds(from: .greatestFiniteMagnitude), 1_000_000_000_000_000_000)
    }

    func testNegativeTimeoutThrowsTimedOut() async {
        let session = FakeSession()
        do {
            _ = try await ActivationWait.isPaired(of: session, timeoutAfter: -1)
            XCTFail("Expected a timeout")
        } catch is WatchActivationTimedOutError {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(session.observerCount, 0)
    }

    func testCancellationThrowsCancellationErrorPromptly() async {
        let session = FakeSession()
        let start = Date()
        let task = Task {
            try await ActivationWait.isPaired(of: session, timeoutAfter: 5)
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected a cancellation")
        } catch is CancellationError {
            XCTAssertLessThan(Date().timeIntervalSince(start), 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(session.observerCount, 0)
    }

    func testCancelledBeforeStartThrowsCancellationError() async {
        let session = FakeSession(isPaired: true)
        let task = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return try await ActivationWait.isPaired(of: session, timeoutAfter: 5)
        }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected a cancellation")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCancelAgainstActivationRaceNeverHangsNorDoubleResumes() async {
        for _ in 0 ..< 200 {
            let session = FakeSession()
            let task = Task {
                try await ActivationWait.isPaired(of: session, timeoutAfter: 1)
            }
            let activation = Task.detached {
                session.activate(isPaired: true)
            }
            task.cancel()
            await activation.value
            let result = try? await task.value
            XCTAssertTrue(result == nil || result == true)
            XCTAssertEqual(session.observerCount, 0)
        }
    }
}
