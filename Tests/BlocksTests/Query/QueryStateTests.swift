@testable import Blocks
import XCTest

final class QueryStateTests: XCTestCase {
    func testDefaultState() {
        let state = QueryState<String>()
        XCTAssertEqual(state.status, .idle)
        XCTAssertNil(state.data)
        XCTAssertNil(state.error)
        XCTAssertNil(state.dataUpdatedAt)
        XCTAssertFalse(state.isFetching)
        XCTAssertFalse(state.isStale)
    }

    func testSuccessState() {
        let now = Date()
        let state = QueryState<Int>(
            status: .success,
            data: 42,
            dataUpdatedAt: now,
            isStale: false
        )
        XCTAssertEqual(state.status, .success)
        XCTAssertEqual(state.data, 42)
        XCTAssertEqual(state.dataUpdatedAt, now)
        XCTAssertFalse(state.isFetching)
    }

    func testStaleWhileRevalidateState() {
        let state = QueryState<String>(
            status: .success,
            data: "cached",
            isFetching: true,
            isStale: true
        )
        XCTAssertEqual(state.status, .success)
        XCTAssertEqual(state.data, "cached")
        XCTAssertTrue(state.isFetching)
        XCTAssertTrue(state.isStale)
    }

    func testErrorState() {
        let error = SimpleMessageError(message: "network error")
        let state = QueryState<String>(status: .error, error: error)
        XCTAssertEqual(state.status, .error)
        XCTAssertNil(state.data)
        XCTAssertNotNil(state.error)
    }

    func testQueryStatusCases() {
        let cases: [QueryStatus] = [.idle, .loading, .success, .error]
        XCTAssertEqual(cases.count, 4)
    }
}
