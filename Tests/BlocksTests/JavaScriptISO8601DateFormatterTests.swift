@testable import Blocks
import XCTest

final class JavaScriptISO8601DateFormatterTests: XCTestCase {
    struct SamplePayload: Codable {
        let message: String
        let creationDate: Date
    }

    // JS code:
    // ```
    // > new Date("2022-01-19T21:21:33.983Z").getTime()
    // 164262729398
    // ```
    let arbitraryDate = Date(timeIntervalSince1970: 1_642_627_293.983)
    let arbitraryDateAsString = "2022-01-19T21:21:33.983Z"

    func testDecoding() throws {
        // This is the output of `JSON.stringify({ message: '👋', creationDate: new Date() })` in JS.
        let json = """
        {"message":"👋","creationDate":"\(arbitraryDateAsString)"}
        """

        let payload = try JSONDecoder.javaScriptISO8601().decode(SamplePayload.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(payload.message, "👋")
        XCTAssertEqual(payload.creationDate, arbitraryDate)
    }

    func testEncoding() throws {
        let payload = SamplePayload(message: "👋", creationDate: arbitraryDate)
        let jsonData = try JSONEncoder.javaScriptISO8601().encode(payload)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        XCTAssert(jsonString.contains("\"creationDate\":\"\(arbitraryDateAsString)\""))
        XCTAssert(jsonString.contains("\"message\":\"👋\""))
    }

    func testDateConversion() {
        XCTAssertEqual(JavaScriptISO8601DateFormatter.date(from: arbitraryDateAsString), arbitraryDate)
    }

    func testInvalidDate() {
        // This is the output of `JSON.stringify({ message: '👋', creationDate: new Date() })` in JS.
        let json = """
        {"message":"👋","creationDate":"2022:01-19T21:21:33.983Z"}
        """

        XCTAssertThrowsError(try JSONDecoder.javaScriptISO8601().decode(SamplePayload.self, from: json.data(using: .utf8)!)) {
            XCTAssertEqual(
                $0.localizedDescription,
                "The data couldn’t be read because it isn’t in the correct format."
            )
        }
    }
}
