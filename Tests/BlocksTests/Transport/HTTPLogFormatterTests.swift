#if canImport(OSLog)
@testable import Blocks
import XCTest

final class HTTPLogFormatterTests: XCTestCase {
    let sut = HTTPLogFormatter(redactedHeaderFields: ["Authorization"])
    let url = URL(string: "https://example.com/graphql")!

    func testRequestWithGraphQLBody() {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer secret", forHTTPHeaderField: "authorization")
        request.httpBody = Data(#"{"operationName":"SignIn","variables":{"slug":"a/b"}}"#.utf8)

        XCTAssertEqual(sut.requestMessage(id: 12, request: request), """
        → #12 POST https://example.com/graphql (SignIn)
        {
          "operationName" : "SignIn",
          "variables" : {
            "slug" : "a/b"
          }
        }

        Authorization: <redacted>
        Content-Type: application/json
        """)
    }

    func testRequestWithoutHeadersNorBody() {
        XCTAssertEqual(sut.requestMessage(id: 1, request: URLRequest(url: url)), "→ #1 GET https://example.com/graphql")
    }

    func testResponseWithTextBody() throws {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/plain", "Set-Cookie": "visible"]
        ))

        let message = sut.responseMessage(
            id: 3,
            request: URLRequest(url: url),
            response: response,
            data: Data("Not found".utf8),
            duration: 0.1814
        )

        XCTAssertEqual(message, """
        ← #3 404 GET https://example.com/graphql · 181 ms · 9 B
        Not found

        Content-Type: text/plain
        Set-Cookie: visible
        """)
    }

    func testResponseWithBinaryBody() throws {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/png"]
        ))

        let message = sut.responseMessage(
            id: 4,
            request: URLRequest(url: url),
            response: response,
            data: Data([0xFF, 0xD8, 0xFF, 0xE0] + Array(repeating: 0, count: 2044)),
            duration: 2.5
        )

        XCTAssertEqual(message, """
        ← #4 200 GET https://example.com/graphql · 2.50 s · 2.0 KB
        <2.0 KB image/png>

        Content-Type: image/png
        """)
    }

    func testResponseWithLongBodyIsTruncated() throws {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/plain"]
        ))
        let body = Data(String(repeating: "é", count: 2000).utf8)

        let message = sut.responseMessage(
            id: 5,
            request: URLRequest(url: url),
            response: response,
            data: body,
            duration: 0
        )

        XCTAssertLessThanOrEqual(message.utf8.count, HTTPLogFormatter.messageByteLimit)
        XCTAssertTrue(message.hasPrefix("← #5 200 GET https://example.com/graphql · 0 ms · 3.9 KB\néé"))
        XCTAssertTrue(message.hasSuffix("é\n… (truncated)"))
        XCTAssertFalse(message.contains("Content-Type"))
    }

    func testError() {
        let message = sut.errorMessage(
            id: 6,
            request: URLRequest(url: url),
            error: URLError(.timedOut),
            duration: 30
        )

        XCTAssertTrue(message.hasPrefix("← #6 ERROR GET https://example.com/graphql · 30.00 s · "))
    }

    @available(iOS 15.0.0, *)
    @available(macOS 12.0, *)
    func testLevels() {
        XCTAssertEqual(LoggingTransport.level(forStatusCode: 200), .debug)
        XCTAssertEqual(LoggingTransport.level(forStatusCode: 302), .debug)
        XCTAssertEqual(LoggingTransport.level(forStatusCode: 404), .error)
        XCTAssertEqual(LoggingTransport.level(forStatusCode: 503), .fault)
    }
}
#endif
