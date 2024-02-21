import Blocks
import XCTest

final class BundleExtensionTests: XCTestCase {
    func testGetContentsAsString() throws {
        let result: String = try Bundle.module.contents(ofResource: "sample-feed", withExtension: "json")
        XCTAssert(result.contains("Manton Reece and Brent Simmons"))
    }

    func testGetContentsAsData() throws {
        let result: Data = try Bundle.module.contents(ofResource: "sample-feed", withExtension: "json")
        XCTAssert(DataFormatter.base64String(from: result).starts(with: "ewoJInZlcnNpb24iOiAiaHR0"))
    }

    func testGetContentsAsStringWithError() throws {
        let errorThrowingExpression: () throws -> Void = {
            let _: String = try Bundle.module.contents(ofResource: "unexisting", withExtension: "json")
        }

        XCTAssertThrowsError(try errorThrowingExpression()) {
            XCTAssertEqual(
                $0.localizedDescription,
                "No URL found for resource unexisting.json"
            )
        }
    }

    func testGetContentsAsDataWithError() throws {
        let errorThrowingExpression: () throws -> Void = {
            let _: Data = try Bundle.module.contents(ofResource: "unexisting", withExtension: "json")
        }

        XCTAssertThrowsError(try errorThrowingExpression()) {
            XCTAssertEqual(
                $0.localizedDescription,
                "No URL found for resource unexisting.json"
            )
        }
    }
}
