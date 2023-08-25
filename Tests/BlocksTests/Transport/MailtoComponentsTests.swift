import Blocks
import XCTest

final class MailtoComponentsTests: XCTestCase {
    func testMailtoURLDecomposition() throws {
        // 📜 Generated with https://mailtolink.me/
        guard let mailToURL = URL(string: "mailto:foo@bar.tld?subject=My%20Subject&body=A%20dummy%20text%0D%0Awith%20paragraphs.") else {
            XCTFail("The provided mailto is not a valid URL")
            return
        }

        let components = try XCTUnwrap(URLComponents(url: mailToURL, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "mailto")
        XCTAssertEqual(components.path, "foo@bar.tld")
        XCTAssertEqual(components.queryItems?.count, 2)
        XCTAssertEqual(components.queryItemValue(forName: "subject"), "My Subject")
        XCTAssertEqual(components.queryItemValue(forName: "body"), "A dummy text\r\nwith paragraphs.")
        dump(components)
    }

    func testBuildingLikeURLComponents() throws {
        var sut = MailtoComponents()
        sut.recipient = "foo@bar.tld"
        sut.subject = "My Subject"
        sut.body = """
        A dummy text
        with paragraphs.
        """

        let mailToURL = sut.url
        XCTAssertEqual(mailToURL?.absoluteString, "mailto:foo@bar.tld?subject=My%20Subject&body=A%20dummy%20text%0D%0Awith%20paragraphs.")
    }

    func testBuildingLikeMFMailComposeViewController() throws {
        var sut = MailtoComponents()
        sut.setToRecipient("foo@bar.tld")
        sut.setSubject("My Subject")
        sut.setMessageBody("""
        A dummy text
        with paragraphs.
        """)

        let mailToURL = sut.url
        XCTAssertEqual(mailToURL?.absoluteString, "mailto:foo@bar.tld?subject=My%20Subject&body=A%20dummy%20text%0D%0Awith%20paragraphs.")
    }
}
