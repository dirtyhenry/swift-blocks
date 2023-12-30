@testable import Blocks
import XCTest

final class EndpointTests: XCTestCase {
    func testBasic() async throws {
        let url = try XCTUnwrap(URL(string: "https://foo.tld/bar"))
        let endpoint = Endpoint<String>(
            json: .get,
            url: url,
            headers: [
                .init(name: "a-header", value: "a-value"),
                .init(name: "b-header", value: nil)
            ]
        )

        XCTAssertEqual(endpoint.request.allHTTPHeaderFields, [
            "Accept": "application/json",
            "a-header": "a-value"
        ])

        XCTAssertEqual(endpoint.description, "GET https://foo.tld/bar")
    }
}
