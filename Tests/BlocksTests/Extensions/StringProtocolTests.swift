import Blocks
import XCTest

final class StringProtocolTests: XCTestCase {
    func testSlugify() {
        XCTAssertEqual(
            "Hello, World! This is an example string with accents: é, è, ê, ñ.".slugify(),
            "hello-world-this-is-an-example-string-with-accents-e-e-e-n"
        )

        XCTAssertEqual("😀 LOL".slugify(), "lol")
        XCTAssertEqual("😀".slugify(), "grinning-face")
        XCTAssertEqual("🎸".slugify(), "guitar")

        XCTAssertEqual(" ".slugify(), "")
        XCTAssertEqual("  ".slugify(), "")
        XCTAssertEqual("   ".slugify(), "")
        XCTAssertEqual("    ".slugify(), "")

        XCTAssertEqual("Hello     Luka Dončić".slugify(), "hello-luka-doncic")
        XCTAssertEqual("สวัสดีชาวโลก".slugify(), "swasdi-chaw-lok")
    }
}
