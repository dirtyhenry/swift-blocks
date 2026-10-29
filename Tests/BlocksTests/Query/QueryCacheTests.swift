@testable import Blocks
import XCTest

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class QueryCacheTests: XCTestCase {
    func testSetAndGet() async {
        let cache = QueryCache()
        let key = AnyQueryKey("test")
        await cache.set(key, data: 42, staleTime: 60, cacheTime: 300)
        let result = await cache.get(key, as: Int.self)
        XCTAssertEqual(result, 42)
    }

    func testGetWrongTypeReturnsNil() async {
        let cache = QueryCache()
        let key = AnyQueryKey("test")
        await cache.set(key, data: 42, staleTime: 60, cacheTime: 300)
        let result = await cache.get(key, as: String.self)
        XCTAssertNil(result)
    }

    func testGetMissingKeyReturnsNil() async {
        let cache = QueryCache()
        let result = await cache.get(AnyQueryKey("missing"), as: Int.self)
        XCTAssertNil(result)
    }

    func testExpiredEntryReturnsNil() async {
        let cache = QueryCache()
        let key = AnyQueryKey("test")
        await cache.set(key, data: "hello", staleTime: 0, cacheTime: 0)
        // cacheTime of 0 means it expires immediately
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        let result = await cache.get(key, as: String.self)
        XCTAssertNil(result)
    }

    func testRemove() async {
        let cache = QueryCache()
        let key = AnyQueryKey("test")
        await cache.set(key, data: 1, staleTime: 60, cacheTime: 300)
        await cache.remove(key)
        let result = await cache.get(key, as: Int.self)
        XCTAssertNil(result)
    }

    func testRemoveMatchingPrefix() async {
        let cache = QueryCache()
        let key1 = AnyQueryKey(QueryKeyPath(["posts", "1"]))
        let key2 = AnyQueryKey(QueryKeyPath(["posts", "2"]))
        let key3 = AnyQueryKey(QueryKeyPath(["users", "1"]))

        await cache.set(key1, data: "post1", staleTime: 60, cacheTime: 300)
        await cache.set(key2, data: "post2", staleTime: 60, cacheTime: 300)
        await cache.set(key3, data: "user1", staleTime: 60, cacheTime: 300)

        await cache.removeMatching(prefix: QueryKeyPath(["posts"]))

        let data1 = await cache.get(key1, as: String.self)
        let data2 = await cache.get(key2, as: String.self)
        let data3 = await cache.get(key3, as: String.self)
        XCTAssertNil(data1)
        XCTAssertNil(data2)
        XCTAssertEqual(data3, "user1")
    }

    func testEvictExpired() async {
        let cache = QueryCache()
        let freshKey = AnyQueryKey("fresh")
        let staleKey = AnyQueryKey("stale")

        await cache.set(freshKey, data: 1, staleTime: 60, cacheTime: 300)
        await cache.set(staleKey, data: 2, staleTime: 0, cacheTime: 0)

        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        await cache.evictExpired()

        let count = await cache.count
        XCTAssertEqual(count, 1)
        let freshData = await cache.get(freshKey, as: Int.self)
        XCTAssertNotNil(freshData)
    }

    func testClear() async {
        let cache = QueryCache()
        await cache.set(AnyQueryKey("a"), data: 1, staleTime: 60, cacheTime: 300)
        await cache.set(AnyQueryKey("b"), data: 2, staleTime: 60, cacheTime: 300)
        let countBefore = await cache.count
        XCTAssertEqual(countBefore, 2)
        await cache.clear()
        let countAfter = await cache.count
        XCTAssertEqual(countAfter, 0)
    }

    func testStaleEntry() async throws {
        let cache = QueryCache()
        let key = AnyQueryKey("test")
        // staleTime = 0 means immediately stale, but cacheTime keeps it in cache
        await cache.set(key, data: "data", staleTime: 0, cacheTime: 300)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        let entry = await cache.getEntry(key)
        XCTAssertNotNil(entry)
        XCTAssertTrue(try XCTUnwrap(entry?.isStale(at: Date())))
        XCTAssertFalse(try XCTUnwrap(entry?.isExpired(at: Date())))
    }
}
