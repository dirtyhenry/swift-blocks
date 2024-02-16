import Blocks
import XCTest

final class CopyUtilsTests: XCTestCase {
    func testLinter() {
        XCTAssertEqual(CopyUtils.lint(input: "L'animal"), "L’animal")
    }
}
