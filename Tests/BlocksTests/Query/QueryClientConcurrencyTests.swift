@testable import Blocks
import XCTest

/// Tests for cancellation, invalidation during a fetch and other concurrent cases.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class QueryClientConcurrencyTests: XCTestCase {
    func testCancellationIsPropagatedAsCancelled() async throws {
        let client = QueryClient(defaultOptions: QueryOptions(retryCount: 1, retryDelay: { _ in 0.01 }))

        // A fetch that always throws CancellationError simulates a cancelled fetch
        do {
            let _: String = try await client.query(key: "cancel-me") {
                throw CancellationError()
            }
            XCTFail("Should have thrown")
        } catch let error as QueryError {
            if case .cancelled = error {
                // expected — CancellationError is wrapped as QueryError.cancelled
            } else {
                XCTFail("Expected QueryError.cancelled, got \(error)")
            }
        }
    }

    func testCancellationDuringRetryBackoffThrowsQueryCancelled() async throws {
        let client = QueryClient(defaultOptions: QueryOptions(
            retryCount: 3,
            retryDelay: { _ in 10.0 } // long delay to ensure cancellation hits during sleep
        ))

        let task = Task<String, any Error> {
            try await client.query(key: "cancel-during-backoff") {
                throw SimpleMessageError(message: "fail")
            }
        }

        // Give the first attempt time to fail and enter backoff sleep
        try await Task.sleep(nanoseconds: 50_000_000)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Should have thrown")
        } catch let error as QueryError {
            if case .cancelled = error {
                // expected
            } else {
                XCTFail("Expected QueryError.cancelled, got \(error)")
            }
        }
    }

    func testCallerCancellationWhileAwaitingInFlightTask() async throws {
        let client = QueryClient()

        // Start a slow fetch
        let slowTask = Task<Int, any Error> {
            try await client.query(key: "slow") {
                try await Task.sleep(nanoseconds: 500_000_000)
                return 42
            }
        }

        // Give the first task time to start
        try await Task.sleep(nanoseconds: 10_000_000)

        // Start a second caller that joins the in-flight task, then cancel it
        let joinerTask = Task<Int, any Error> {
            try await client.query(key: "slow") {
                42 // won't be called — deduplication
            }
        }

        try await Task.sleep(nanoseconds: 10_000_000)
        joinerTask.cancel()

        do {
            _ = try await joinerTask.value
            XCTFail("Should have thrown due to cancellation")
        } catch let error as QueryError {
            guard case .cancelled = error else {
                XCTFail("Expected QueryError.cancelled, got \(error)")
                return
            }
        }

        // The original task should still complete successfully
        let result = try await slowTask.value
        XCTAssertEqual(result, 42)
    }

    func testCancellingOriginatorDoesNotCancelDeduplicatedJoiner() async throws {
        let counter = CallCounter()
        let client = QueryClient()

        let originator = Task<Int, any Error> {
            try await client.query(key: "shared") {
                await counter.increment()
                try await Task.sleep(nanoseconds: 200_000_000)
                return 99
            }
        }

        // Give the originator time to start the fetch.
        try await Task.sleep(nanoseconds: 20_000_000)

        let joiner = Task<Int, any Error> {
            try await client.query(key: "shared") {
                await counter.increment()
                return 99 // would not run — deduplicated
            }
        }

        // Give the joiner time to register as a waiter.
        try await Task.sleep(nanoseconds: 20_000_000)
        originator.cancel()

        // The joiner should still receive the value because the shared fetch
        // continues running even though the originator was cancelled.
        let joinerValue = try await joiner.value
        XCTAssertEqual(joinerValue, 99)

        // The originator should observe cancellation.
        do {
            _ = try await originator.value
            XCTFail("Originator should have thrown")
        } catch let error as QueryError {
            guard case .cancelled = error else {
                XCTFail("Expected QueryError.cancelled, got \(error)")
                return
            }
        }

        let calls = await counter.count
        XCTAssertEqual(calls, 1, "Fetch closure should run once across both callers")
    }

    func testCancellingJoinerExitsWithQueryCancelledQuickly() async throws {
        let client = QueryClient()

        let originator = Task<Int, any Error> {
            try await client.query(key: "slow-shared") {
                try await Task.sleep(nanoseconds: 500_000_000)
                return 7
            }
        }

        try await Task.sleep(nanoseconds: 20_000_000)

        let joiner = Task<Int, any Error> {
            try await client.query(key: "slow-shared") { 7 }
        }

        try await Task.sleep(nanoseconds: 20_000_000)

        let start = Date()
        joiner.cancel()

        do {
            _ = try await joiner.value
            XCTFail("Joiner should have thrown")
        } catch let error as QueryError {
            guard case .cancelled = error else {
                XCTFail("Expected QueryError.cancelled, got \(error)")
                return
            }
        }
        let elapsed = Date().timeIntervalSince(start)
        // The joiner should exit promptly (well before the 500ms shared fetch finishes).
        XCTAssertLessThan(elapsed, 0.3, "Joiner did not exit promptly on cancellation")

        // The originator's shared fetch should still complete successfully.
        let value = try await originator.value
        XCTAssertEqual(value, 7)
    }

    func testInvalidateDuringInFlightCancelsAllWaiters() async throws {
        let client = QueryClient()

        let first = Task<Int, any Error> {
            try await client.query(key: "invalidate-me") {
                try await Task.sleep(nanoseconds: 500_000_000)
                return 1
            }
        }
        try await Task.sleep(nanoseconds: 20_000_000)
        let second = Task<Int, any Error> {
            try await client.query(key: "invalidate-me") { 1 }
        }

        try await Task.sleep(nanoseconds: 20_000_000)
        await client.invalidate("invalidate-me")

        for task in [first, second] {
            do {
                _ = try await task.value
                XCTFail("Task should have thrown after invalidation")
            } catch let error as QueryError {
                guard case .cancelled = error else {
                    XCTFail("Expected QueryError.cancelled, got \(error)")
                    return
                }
            }
        }
    }

    func testFetchFromBeforeInvalidationDoesNotSettleTheNextFetch() async throws {
        let client = QueryClient(defaultOptions: QueryOptions(staleTime: 60, retryCount: 0))

        // This fetch ignores cancellation, so it completes after the invalidation.
        let first = Task<Int, any Error> {
            try await client.query(key: "race") {
                await uncancellableSleep(seconds: 0.1)
                return 1
            }
        }
        try await Task.sleep(nanoseconds: 20_000_000)
        await client.invalidate("race")
        _ = try? await first.value

        let second: Int = try await client.query(key: "race") {
            await uncancellableSleep(seconds: 0.3)
            return 2
        }

        XCTAssertEqual(second, 2)
        let cached = await client.getQueryData("race", as: Int.self)
        XCTAssertEqual(cached, 2)
    }

    func testInvalidatedFetchDoesNotWriteToTheCache() async throws {
        let client = QueryClient(defaultOptions: QueryOptions(staleTime: 60, retryCount: 0))

        let task = Task<Int, any Error> {
            try await client.query(key: "late") {
                await uncancellableSleep(seconds: 0.05)
                return 1
            }
        }
        try await Task.sleep(nanoseconds: 10_000_000)
        await client.invalidate("late")
        _ = try? await task.value
        try await Task.sleep(nanoseconds: 100_000_000)

        let cached = await client.getQueryData("late", as: Int.self)
        XCTAssertNil(cached)
        let state = await client.state(for: "late", as: Int.self)
        XCTAssertNil(state)
    }

    func testPrefetchSkipsFreshData() async throws {
        let counter = CallCounter()
        let client = QueryClient(defaultOptions: QueryOptions(staleTime: 60))
        await client.setQueryData("fresh", data: "cached")

        await client.prefetch(key: "fresh") {
            await counter.increment()
            return "fetched"
        }
        try await Task.sleep(nanoseconds: 50_000_000)

        let count = await counter.count
        XCTAssertEqual(count, 0)
        let data = await client.getQueryData("fresh", as: String.self)
        XCTAssertEqual(data, "cached")
    }

    func testStateHasNoDataAfterCacheExpiry() async throws {
        let client = QueryClient(defaultOptions: QueryOptions(staleTime: 0, cacheTime: 0.05))
        let _: Int = try await client.query(key: "expiring") { 1 }
        try await Task.sleep(nanoseconds: 100_000_000)

        let state = await client.state(for: "expiring", as: Int.self)
        XCTAssertNil(state?.data)
    }

    func testNonFiniteRetryDelayDoesNotCrash() async {
        let client = QueryClient(defaultOptions: QueryOptions(retryCount: 1, retryDelay: { _ in .infinity }))
        do {
            let _: Int = try await client.query(key: "infinite-delay") {
                throw URLError(.timedOut)
            }
            XCTFail("Expected an error")
        } catch let QueryError.allRetriesFailed(attempts, _) {
            XCTAssertEqual(attempts, 2)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

/// Sleeps without a reaction to the cancellation of the task, as a fetch that does not check
/// for cancellation.
private func uncancellableSleep(seconds: Double) async {
    await withCheckedContinuation { continuation in
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) {
            continuation.resume()
        }
    }
}
