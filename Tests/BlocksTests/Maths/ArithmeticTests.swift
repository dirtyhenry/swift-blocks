import Blocks
import XCTest

final class ArithmeticTests: XCTestCase {
    func testAverageInt() {
        XCTAssertEqual([Int]().average(), nil)
        XCTAssertEqual([1].average(), 1.0)
        XCTAssertEqual([1, 2].average(), 1.5)
    }

    func testAverageDouble() {
        XCTAssertEqual([Double]().average(), nil)
        XCTAssertEqual([1.0].average(), 1.0)
        XCTAssertEqual([1.0, 2.0].average(), 1.5)
    }
}
