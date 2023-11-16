import Blocks
import XCTest

final class URLRequestHeaderItemTests: XCTestCase {
    func testBasic() async throws {
        var request = URLRequest(url: URL(string: "https://foo.tld/bar")!)
        // This is an example from the [RFC 7617](https://datatracker.ietf.org/doc/html/rfc7617):
        //
        // > If the user agent wishes to send the user-id "Aladdin" and password
        // > "open sesame", it would use the following header field:
        // >
        // >    Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==
        request.setHTTPHeaderField(.basicAuthentication(username: "Aladdin", password: "open sesame"))
        request.setHTTPHeaderField(.init(name: "Foo", value: "Bar"))
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Foo"), "Bar")
    }
}
