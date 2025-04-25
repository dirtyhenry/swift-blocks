@testable import Blocks
import XCTest

final class JSONTests: XCTestCase {
    struct SampleCodable: Codable {
        let zArray: [String]
        let yObject: [String: Bool]
        let xNullable: String?
        let mOpinionatedDate: Date
        let dBool: Bool
        let cString: String
        let bNumber: Double
        let aNumber: Int
    }

    func testStringify() throws {
        let sampleCodable = SampleCodable(
            zArray: ["z", "y", "x"],
            yObject: ["z": true, "y": false],
            xNullable: nil,
            mOpinionatedDate: Date(timeIntervalSince1970: 123_456_789),
            dBool: true,
            cString: "Hello JSON / Hello \"World\"",
            bNumber: 12.34,
            aNumber: 5678
        )
        let stringifiedCodable = JSON.stringify(sampleCodable)
        XCTAssertEqual(stringifiedCodable, """
        {
          "aNumber" : 5678,
          "bNumber" : 12.34,
          "cString" : "Hello JSON / Hello \\"World\\"",
          "dBool" : true,
          "mOpinionatedDate" : "1973-11-29T21:33:09.000Z",
          "yObject" : {
            "y" : false,
            "z" : true
          },
          "zArray" : [
            "z",
            "y",
            "x"
          ]
        }
        """)
    }
}
