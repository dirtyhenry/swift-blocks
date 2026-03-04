@testable import Blocks
import XCTest

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class QueryClientTests: XCTestCase {
    func testBasicFetch() async throws {
        let client = QueryClient()
        let result: String = try await client.query(key: "test") {
            "hello"
        }
        XCTAssertEqual(result, "hello")
    }

    func testCacheHit() async throws {
        let counter = CallCounter()
        let client = QueryClient(defaultOptions: QueryOptions(staleTime: 60))

        let first: Int = try await client.query(key: "count") {
            await counter.increment()
            return 42
        }
        let second: Int = try await client.query(key: "count") {
            await counter.increment()
            return 99
        }

        XCTAssertEqual(first, 42)
        XCTAssertEqual(second, 42)
        let count = await counter.count
        XCTAssertEqual(count, 1)
    }

    func testStaleDataRefetchesInBackground() async throws {
        let counter = CallCounter()
        let client = QueryClient(defaultOptions: QueryOptions(staleTime: 0, cacheTime: 300))

        let first: Int = try await client.query(key: "data") {
            await counter.increment()
            return 1
        }
        XCTAssertEqual(first, 1)

        // Small delay so the entry becomes stale (staleTime = 0)
        try await Task.sleep(nanoseconds: 10_000_000)

        // Second call returns stale data immediately, triggers background refetch
        let second: Int = try await client.query(key: "data") {
            await counter.increment()
            return 2
        }
        XCTAssertEqual(second, 1) // stale data returned

        // Wait for background refetch to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        let count = await counter.count
        XCTAssertEqual(count, 2)
    }

    func testDeduplication() async throws {
        let counter = CallCounter()
        let client = QueryClient()

        async let a: Int = client.query(key: "dedup") {
            await counter.increment()
            try await Task.sleep(nanoseconds: 50_000_000)
            return 42
        }
        async let b: Int = client.query(key: "dedup") {
            await counter.increment()
            try await Task.sleep(nanoseconds: 50_000_000)
            return 42
        }

        let results = try await [a, b]
        XCTAssertEqual(results, [42, 42])
        let count = await counter.count
        XCTAssertEqual(count, 1)
    }

    func testSetAndGetQueryData() async {
        let client = QueryClient()
        await client.setQueryData("manual", data: "injected")
        let result = await client.getQueryData("manual", as: String.self)
        XCTAssertEqual(result, "injected")
    }

    func testInvalidate() async throws {
        let client = QueryClient(defaultOptions: QueryOptions(staleTime: 60))
        let _: String = try await client.query(key: "to-invalidate") { "cached" }

        await client.invalidate("to-invalidate")

        let data = await client.getQueryData("to-invalidate", as: String.self)
        XCTAssertNil(data)
    }

    func testInvalidateMatchingPrefix() async throws {
        let client = QueryClient(defaultOptions: QueryOptions(staleTime: 60))
        let key1 = QueryKeyPath(["posts", "1"])
        let key2 = QueryKeyPath(["posts", "2"])
        let key3 = QueryKeyPath(["users", "1"])

        let _: String = try await client.query(key: key1) { "post1" }
        let _: String = try await client.query(key: key2) { "post2" }
        let _: String = try await client.query(key: key3) { "user1" }

        await client.invalidateMatching(prefix: QueryKeyPath(["posts"]))

        let data1 = await client.getQueryData(key1, as: String.self)
        let data2 = await client.getQueryData(key2, as: String.self)
        let data3 = await client.getQueryData(key3, as: String.self)
        XCTAssertNil(data1)
        XCTAssertNil(data2)
        XCTAssertEqual(data3, "user1")
    }

    func testInvalidateAll() async throws {
        let client = QueryClient(defaultOptions: QueryOptions(staleTime: 60))
        let _: String = try await client.query(key: "a") { "1" }
        let _: String = try await client.query(key: "b") { "2" }

        await client.invalidateAll()

        let dataA = await client.getQueryData("a", as: String.self)
        let dataB = await client.getQueryData("b", as: String.self)
        XCTAssertNil(dataA)
        XCTAssertNil(dataB)
    }

    func testQueryState() async throws {
        let client = QueryClient()
        let _: Int = try await client.query(key: "stateful") { 42 }
        let state = await client.state(for: "stateful", as: Int.self)
        XCTAssertEqual(state?.status, .success)
        XCTAssertEqual(state?.data, 42)
        XCTAssertNotNil(state?.dataUpdatedAt)
    }

    func testRetryOnFailure() async throws {
        let counter = CallCounter()
        let client = QueryClient(defaultOptions: QueryOptions(
            retryCount: 2,
            retryDelay: { _ in 0.01 }
        ))

        let result: String = try await client.query(key: "retry") {
            let count = await counter.increment()
            if count < 3 {
                throw SimpleMessageError(message: "fail \(count)")
            }
            return "success"
        }

        XCTAssertEqual(result, "success")
        let count = await counter.count
        XCTAssertEqual(count, 3)
    }

    func testAllRetriesExhausted() async {
        let client = QueryClient(defaultOptions: QueryOptions(
            retryCount: 1,
            retryDelay: { _ in 0.01 }
        ))

        do {
            let _: String = try await client.query(key: "always-fail") {
                throw SimpleMessageError(message: "always fails")
            }
            XCTFail("Should have thrown")
        } catch let error as QueryError {
            if case let .allRetriesFailed(attempts, _) = error {
                XCTAssertEqual(attempts, 2) // 1 initial + 1 retry
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testPrefetch() async throws {
        let client = QueryClient()
        await client.prefetch(key: "prefetched") {
            "data"
        }

        // Wait for background task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        let data = await client.getQueryData("prefetched", as: String.self)
        XCTAssertEqual(data, "data")
    }

    func testQueryErrorDescriptions() throws {
        let cancelled = QueryError.cancelled
        XCTAssertNotNil(cancelled.errorDescription)

        let retries = QueryError.allRetriesFailed(
            attempts: 3,
            lastError: SimpleMessageError(message: "fail")
        )
        XCTAssertTrue(try XCTUnwrap(retries.errorDescription?.contains("3")))

        let mismatch = QueryError.typeMismatch(expected: "Int", actual: "String")
        XCTAssertTrue(try XCTUnwrap(mismatch.errorDescription?.contains("Int")))
    }

    func testBackgroundRefetchFailureClearsInFlightAndState() async throws {
        let client = QueryClient(defaultOptions: QueryOptions(
            staleTime: 0,
            cacheTime: 300,
            retryCount: 0
        ))

        // Seed with initial data
        let first: String = try await client.query(key: "bg-fail") { "initial" }
        XCTAssertEqual(first, "initial")

        // Let it become stale
        try await Task.sleep(nanoseconds: 10_000_000)

        // Trigger a background refetch that will fail
        let _: String = try await client.query(key: "bg-fail") {
            throw SimpleMessageError(message: "network error")
        }

        // Wait for background refetch to fail
        try await Task.sleep(nanoseconds: 100_000_000)

        // State should have isFetching reset to false
        let state = await client.state(for: "bg-fail", as: String.self)
        XCTAssertEqual(state?.isFetching, false)
        XCTAssertEqual(state?.data, "initial") // original data preserved

        // A new background refetch should be possible (not blocked by stale in-flight task)
        let _: String = try await client.query(key: "bg-fail") { "recovered" }

        try await Task.sleep(nanoseconds: 100_000_000)

        let data = await client.getQueryData("bg-fail", as: String.self)
        XCTAssertEqual(data, "recovered")
    }

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
                return 42 // won't be called — deduplication
            }
        }

        try await Task.sleep(nanoseconds: 10_000_000)
        joinerTask.cancel()

        do {
            _ = try await joinerTask.value
            XCTFail("Should have thrown due to cancellation")
        } catch is CancellationError {
            // expected — the cancellation check after await throws CancellationError
        } catch {
            // Also acceptable if it surfaces differently
        }

        // The original task should still complete successfully
        let result = try await slowTask.value
        XCTAssertEqual(result, 42)
    }

    func testQueryOptionsDefaults() {
        let opts = QueryOptions()
        XCTAssertEqual(opts.staleTime, 0)
        XCTAssertEqual(opts.cacheTime, 300)
        XCTAssertEqual(opts.retryCount, 3)
    }

    func testExponentialBackoff() {
        XCTAssertEqual(QueryOptions.exponentialBackoff(attempt: 0), 1.0)
        XCTAssertEqual(QueryOptions.exponentialBackoff(attempt: 1), 2.0)
        XCTAssertEqual(QueryOptions.exponentialBackoff(attempt: 2), 4.0)
        XCTAssertEqual(QueryOptions.exponentialBackoff(attempt: 5), 30.0) // capped
        XCTAssertEqual(QueryOptions.exponentialBackoff(attempt: 10), 30.0)
    }
}

// MARK: - Test Helpers

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
actor CallCounter {
    var count = 0

    @discardableResult
    func increment() -> Int {
        count += 1
        return count
    }
}
