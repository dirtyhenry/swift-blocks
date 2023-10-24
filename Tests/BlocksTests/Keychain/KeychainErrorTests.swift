@testable import Blocks
import XCTest

final class KeychainErrorTests: XCTestCase {
    func testLocalizedError() {
        let sut = KeychainError.unhandledError(status: errSecDuplicateKeychain)
        XCTAssertEqual(sut.localizedDescription, "A keychain with the same name already exists.")
    }
}
