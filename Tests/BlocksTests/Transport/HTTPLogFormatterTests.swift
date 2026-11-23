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

    func testRequestWithGraphQLQuery() throws {
        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com/graphql?operationName=SignIn")))

        XCTAssertEqual(
            sut.requestMessage(id: 2, request: request),
            "→ #2 GET https://example.com/graphql?operationName=SignIn (SignIn)"
        )
    }

    func testRequestWithoutHeadersNorBody() {
        XCTAssertEqual(sut.requestMessage(id: 1, request: URLRequest(url: url)), "→ #1 GET https://example.com/graphql")
    }

    func testRequestWithStreamedBody() {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBodyStream = InputStream(data: Data("streamed".utf8))

        XCTAssertEqual(sut.requestMessage(id: 7, request: request), """
        → #7 POST https://example.com/graphql
        <streamed body>
        """)
    }

    func testResponseWithTextBody() throws {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: nil,
            headerFields: ["Set-Cookie": "visible", "Content-Type": "text/plain"]
        ))

        let message = sut.message(
            summary: sut.responseSummary(
                id: 3,
                request: URLRequest(url: url),
                response: response,
                byteCount: 9,
                duration: 0.1814,
                redactsURL: false
            ),
            details: sut.responseDetails(response: response, data: Data("Not found".utf8))
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
        let body = Data([0xFF, 0xD8, 0xFF, 0xE0] + Array(repeating: 0, count: 2044))

        XCTAssertEqual(sut.responseDetails(response: response, data: body), """
        <2.0 KB image/png>

        Content-Type: image/png
        """)
    }

    func testBinaryDetection() {
        XCTAssertTrue(HTTPLogFormatter.isBinary(contentType: "application/x-protobuf", body: Data("abc".utf8)))
        XCTAssertTrue(HTTPLogFormatter.isBinary(contentType: nil, body: Data([0x61, 0x00, 0x62])))
        XCTAssertFalse(HTTPLogFormatter.isBinary(contentType: "text/plain", body: Data("abc".utf8)))
        XCTAssertFalse(HTTPLogFormatter.isBinary(contentType: nil, body: Data("abc".utf8)))
    }

    func testResponseWithLongBodyIsTruncated() throws {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/plain"]
        ))
        let body = Data(String(repeating: "é", count: 2000).utf8)

        let message = sut.message(
            summary: "summary",
            details: sut.responseDetails(response: response, data: body)
        )

        XCTAssertLessThanOrEqual(message.utf8.count, HTTPLogFormatter.messageByteLimit)
        XCTAssertTrue(message.hasPrefix("summary\néé"))
        XCTAssertTrue(message.hasSuffix("é\n… (truncated)"))
        XCTAssertFalse(message.contains("Content-Type"))
    }

    func testLargeJSONBodyIsNotParsed() throws {
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        let items = String(repeating: "1,", count: HTTPLogFormatter.parsedBodyByteLimit)
        let body = Data("{\"items\":[\(items)1]}".utf8)

        let details = try XCTUnwrap(sut.responseDetails(response: response, data: body))

        XCTAssertTrue(details.hasPrefix(#"{"items":[1,1,"#))
    }

    func testRedactedURL() throws {
        let url = try XCTUnwrap(URL(string: "https://user:pass@example.com/items?api_key=SECRET#top"))
        let request = URLRequest(url: url)

        let summary = sut.errorSummary(
            id: 6,
            request: request,
            error: URLError(.timedOut),
            duration: 30,
            redactsURL: true
        )

        XCTAssertTrue(summary.hasPrefix("← #6 ERROR GET https://example.com/items?… · 30.00 s · "))
        XCTAssertEqual(sut.detailsMessage(id: 6, request: request, details: "Not found"), """
        ↳ #6 details
        https://user:pass@example.com/items?api_key=SECRET#top

        Not found
        """)
    }

    func testSignpostBeginMessageHasRedactedURLAndOperationName() throws {
        var request = try URLRequest(url: XCTUnwrap(URL(string: "https://user:pass@example.com/graphql?token=SECRET")))
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"operationName":"SignIn"}"#.utf8)

        XCTAssertEqual(
            sut.signpostBeginMessage(id: 12, request: request),
            "#12 POST https://example.com/graphql?… (SignIn)"
        )
    }

    func testSignpostEndMessages() throws {
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))

        XCTAssertEqual(sut.signpostEndMessage(response: response, byteCount: 1536), "404 · 1.5 KB")
        XCTAssertTrue(sut.signpostEndMessage(error: URLError(.timedOut)).hasPrefix("ERROR · "))
    }

    func testUnits() {
        XCTAssertEqual(HTTPLogFormatter.format(duration: 0.1814), "181 ms")
        XCTAssertEqual(HTTPLogFormatter.format(duration: 0.9996), "1.00 s")
        XCTAssertEqual(HTTPLogFormatter.format(byteCount: 1023), "1023 B")
        XCTAssertEqual(HTTPLogFormatter.format(byteCount: 1536), "1.5 KB")
        XCTAssertEqual(HTTPLogFormatter.format(byteCount: 1_048_575), "1.0 MB")
    }

    @available(iOS 15.0.0, *)
    @available(macOS 12.0, *)
    func testLevels() {
        XCTAssertEqual(LoggingTransport.level(for: URLError(.timedOut)), .fault)
        XCTAssertEqual(LoggingTransport.level(for: URLError(.cancelled)), .debug)
        XCTAssertEqual(LoggingTransport.level(for: CancellationError()), .debug)
        XCTAssertEqual(LoggingTransport.level(forStatusCode: 200), .debug)
        XCTAssertEqual(LoggingTransport.level(forStatusCode: 302), .debug)
        XCTAssertEqual(LoggingTransport.level(forStatusCode: 404), .error)
        XCTAssertEqual(LoggingTransport.level(forStatusCode: 503), .fault)
    }
}
#endif
