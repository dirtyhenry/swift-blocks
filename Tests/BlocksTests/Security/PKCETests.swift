#if canImport(CryptoKit)
@testable import Blocks
import XCTest

final class PKCETests: XCTestCase {
    func testSeeding() {
        let pkceSeeds = PKCE.ClientSeeds(octets: [
            116, 24, 223, 180, 151, 153, 224, 37, 79, 250, 96, 125, 216, 173,
            187, 186, 22, 212, 37, 77, 105, 214, 191, 240, 91, 88, 5, 88, 83,
            132, 141, 121
        ])
        XCTAssertEqual(pkceSeeds.codeVerifier, "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        XCTAssertEqual(try pkceSeeds.codeChallenge(), "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }
}
#endif
