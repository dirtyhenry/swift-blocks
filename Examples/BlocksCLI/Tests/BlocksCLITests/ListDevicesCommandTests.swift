import Blocks
@testable import BlocksCLI
import Foundation
import XCTest

final class ListDevicesCommandTests: XCTestCase {
    func testParsingOfOutput() throws {
        let testData: Data = try Bundle.module.contents(
            ofResource: "simctl-list-devices",
            withExtension: "json"
        )

        let decoder = JSONDecoder()
        let result = try decoder.decode(DeviceContainer.self, from: testData)

        let all17dot2Devices = try XCTUnwrap(result.devices["com.apple.CoreSimulator.SimRuntime.iOS-17-2"])
        XCTAssert(all17dot2Devices.count > 5)
    }
}
