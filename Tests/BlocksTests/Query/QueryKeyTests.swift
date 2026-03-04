@testable import Blocks
import XCTest

final class QueryKeyTests: XCTestCase {
    func testStringConformsToQueryKey() {
        let key: some QueryKey = "my-key"
        let anyKey = AnyQueryKey(key)
        XCTAssertEqual(anyKey.unwrap(as: String.self), "my-key")
    }

    func testAnyQueryKeyEquality() {
        let a = AnyQueryKey("hello")
        let b = AnyQueryKey("hello")
        let c = AnyQueryKey("world")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
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
        let a: QueryKeyPath = ["posts", "123"]
        let b: QueryKeyPath = ["posts", "123"]
        let c: QueryKeyPath = ["posts", "456"]
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
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
