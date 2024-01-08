#if canImport(Security)
import Blocks
import XCTest

final class SecurityUtilsTests: XCTestCase {
    func testGenerateCryptographicallySecureRandomOctets() {
        measure {
            do {
                let firstOccurrence = try SecurityUtils.generateCryptographicallySecureRandomOctets(count: 10)
                let secondOccurrence = try SecurityUtils.generateCryptographicallySecureRandomOctets(count: 10)

                XCTAssertEqual(firstOccurrence.count, 10)
                XCTAssertEqual(secondOccurrence.count, 10)
                XCTAssertNotEqual(firstOccurrence, secondOccurrence)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
#endif
