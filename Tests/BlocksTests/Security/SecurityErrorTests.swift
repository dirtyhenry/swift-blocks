#if canImport(Security)
@testable import Blocks
import XCTest

final class SecurityErrorTests: XCTestCase {
    func testLocalizedError() {
        let sut = SecurityError.unhandledError(status: errSecDuplicateKeychain)
        XCTAssertEqual(sut.localizedDescription, "A keychain with the same name already exists.")
    }
}
#endif
