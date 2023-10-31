@testable import Blocks
import os
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
            cString: "Hello JSON",
            bNumber: 12.34,
            aNumber: 5678
        )
        let stringifiedCodable = JSON.stringify(sampleCodable)
        XCTAssertEqual(stringifiedCodable, """
        {
          "aNumber" : 5678,
          "bNumber" : 12.34,
          "cString" : "Hello JSON",
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

        // Test how things look with print and logger
        JSON.print(sampleCodable)

        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: "swift-blocks", category: "JSON")
            logger.info("JSON public: \(JSON.stringify(sampleCodable), privacy: .public)")
            logger.info("JSON private: \(JSON.stringify(sampleCodable), privacy: .private)")
            logger.info("JSON auto/hash: \(JSON.stringify(sampleCodable), privacy: .auto(mask: .hash))")
        }
    }
}
