@testable import Blocks
import XCTest

final class JavaScriptISO8601DateFormatterTests: XCTestCase {
    struct SamplePayload: Codable {
        let message: String
        let creationDate: Date
    }

    func testDecoding() throws {
        // This is the output of `JSON.stringify({ message: '👋', creationDate: new Date() })` in JS.
        let json = """
        {"message":"👋","creationDate":"2022-01-19T21:21:33.983Z"}
        """

        let payload = try JSONDecoder.javaScriptISO8601().decode(SamplePayload.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(payload.message, "👋")
        // new Date("2022-01-19T21:21:33.983Z").getTime() => 1642627293983
        XCTAssertEqual(payload.creationDate.timeIntervalSince1970, 1_642_627_293.983)
    }

    func testEncoding() throws {
        let payload = SamplePayload(message: "👋", creationDate: Date(timeIntervalSince1970: 1_642_627_293.983))
        let jsonData = try JSONEncoder.javaScriptISO8601().encode(payload)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        XCTAssert(jsonString.contains("\"creationDate\":\"2022-01-19T21:21:33.983Z\""))
        XCTAssert(jsonString.contains("\"message\":\"👋\""))
    }
}
