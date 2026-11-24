@testable import Blocks
import XCTest

final class OAuthCredentialsTests: XCTestCase {
    func testIsExpiredComparesWithTheExpiryDate() {
        let expiresAt = Date(timeIntervalSince1970: 1_000_000)
        let credentials = OAuthCredentials(accessToken: "access", expiresAt: expiresAt, refreshToken: nil)

        XCTAssertFalse(credentials.isExpired(at: expiresAt.addingTimeInterval(-1)))
        XCTAssertTrue(credentials.isExpired(at: expiresAt))
        XCTAssertTrue(credentials.isExpired(at: expiresAt.addingTimeInterval(1)))
    }

    func testCredentialsWithoutExpiryDateNeverExpire() {
        let credentials = OAuthCredentials(accessToken: "access")
        XCTAssertFalse(credentials.isExpired(at: .distantFuture))
    }

    func testJSONRoundTrip() throws {
        let credentials = OAuthCredentials(
            accessToken: "access",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000),
            refreshToken: "refresh"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(credentials)
        let decoded = try decoder.decode(OAuthCredentials.self, from: data)

        XCTAssertEqual(decoded, credentials)
    }
}
