@testable import Blocks
import XCTest

final class QueryKeyTests: XCTestCase {
    func testStringConformsToQueryKey() {
        let key: some QueryKey = "my-key"
        let anyKey = AnyQueryKey(key)
        XCTAssertEqual(anyKey.unwrap(as: String.self), "my-key")
    }

    func testAnyQueryKeyEquality() {
        let first = AnyQueryKey("hello")
        let second = AnyQueryKey("hello")
        let third = AnyQueryKey("world")
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, third)
    }

    func testAnyQueryKeyUnwrapWrongType() {
        let key = AnyQueryKey("hello")
        XCTAssertNil(key.unwrap(as: QueryKeyPath.self))
    }

    func testQueryKeyPathHasPrefix() {
        let key: QueryKeyPath = ["posts", "123", "comments"]
        XCTAssertTrue(key.hasPrefix(["posts"]))
        XCTAssertTrue(key.hasPrefix(["posts", "123"]))
        XCTAssertTrue(key.hasPrefix(["posts", "123", "comments"]))
        XCTAssertFalse(key.hasPrefix(["users"]))
        XCTAssertFalse(key.hasPrefix(["posts", "456"]))
        XCTAssertFalse(key.hasPrefix(["posts", "123", "comments", "extra"]))
    }

    func testQueryKeyPathEquality() {
        let first: QueryKeyPath = ["posts", "123"]
        let second: QueryKeyPath = ["posts", "123"]
        let third: QueryKeyPath = ["posts", "456"]
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, third)
    }

    func testQueryKeyPathEmptyPrefix() {
        let key: QueryKeyPath = ["posts"]
        XCTAssertTrue(key.hasPrefix([]))
    }

    func testAnyQueryKeyWithQueryKeyPath() {
        let path: QueryKeyPath = ["users", "42"]
        let anyKey = AnyQueryKey(path)
        let unwrapped = anyKey.unwrap(as: QueryKeyPath.self)
        XCTAssertEqual(unwrapped, path)
    }
}
