@testable import Blocks
import XCTest

final class ExtensionTests: XCTestCase {
    #if canImport(UIKit)
        func testAllFontNames() throws {
            let sut = UIFont.allFontNames()
            // It will be hard to guess the how fonts will evolve over iOS versions
            // but we can assume that it will keep more than 200 options…
            XCTAssert(sut.count > 200)
            // … and that Futura-Bold will be one of them.
            XCTAssert(sut.contains("Futura-Bold"))
        }
    #endif
}
