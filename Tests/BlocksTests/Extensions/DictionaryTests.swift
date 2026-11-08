import Blocks
import XCTest

final class DictionaryTests: XCTestCase {
    struct InvalidKey: Error {}

    func testMapKeyTransformsKeysAndKeepsValues() {
        XCTAssertEqual(["1": "one", "2": "two"].mapKey { Int($0)! }, [1: "one", 2: "two"])
    }

    func testMapKeyRethrows() {
        XCTAssertThrowsError(try ["a": 1].mapKey { _ -> Int in throw InvalidKey() }) { error in
            XCTAssertTrue(error is InvalidKey)
        }
    }
}
