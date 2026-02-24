@testable import Blocks
import XCTest

final class StyledTextTests: XCTestCase {
    private let esc = "\u{001B}"

    // MARK: - Plain text

    func testUnstyledTextHasNoEscapeCodes() {
        let styled = StyledText("hello")
        XCTAssertEqual(styled.description, "hello")
    }

    // MARK: - Foreground colors

    func testEachForegroundColor() {
        let cases: [(KeyPath<String, StyledText>, Int)] = [
            (\.black, 30), (\.red, 31), (\.green, 32), (\.yellow, 33),
            (\.blue, 34), (\.magenta, 35), (\.cyan, 36), (\.white, 37)
        ]
        for (keyPath, code) in cases {
            let result = "x"[keyPath: keyPath].description
            XCTAssertEqual(result, "\(esc)[\(code)mx\(esc)[0m", "Failed for code \(code)")
        }
    }

    // MARK: - Background colors

    func testEachBackgroundColor() {
        let cases: [(KeyPath<String, StyledText>, Int)] = [
            (\.onBlack, 40), (\.onRed, 41), (\.onGreen, 42), (\.onYellow, 43),
            (\.onBlue, 44), (\.onMagenta, 45), (\.onCyan, 46), (\.onWhite, 47)
        ]
        for (keyPath, code) in cases {
            let result = "x"[keyPath: keyPath].description
            XCTAssertEqual(result, "\(esc)[\(code)mx\(esc)[0m", "Failed for code \(code)")
        }
    }

    // MARK: - Combined colors

    func testForegroundAndBackground() {
        let result = "hi".red.onBlue.description
        XCTAssertEqual(result, "\(esc)[31;44mhi\(esc)[0m")
    }

    // MARK: - Modifiers

    func testBold() {
        XCTAssertEqual("x".bold.description, "\(esc)[1mx\(esc)[0m")
    }

    func testDim() {
        XCTAssertEqual("x".dim.description, "\(esc)[2mx\(esc)[0m")
    }

    func testItalic() {
        XCTAssertEqual("x".italic.description, "\(esc)[3mx\(esc)[0m")
    }

    func testUnderline() {
        XCTAssertEqual("x".underline.description, "\(esc)[4mx\(esc)[0m")
    }

    func testInverse() {
        XCTAssertEqual("x".inverse.description, "\(esc)[7mx\(esc)[0m")
    }

    func testHidden() {
        XCTAssertEqual("x".hidden.description, "\(esc)[8mx\(esc)[0m")
    }

    func testStrikethrough() {
        XCTAssertEqual("x".strikethrough.description, "\(esc)[9mx\(esc)[0m")
    }

    // MARK: - Modifier + color combination

    func testBoldRedOnWhite() {
        let result = "err".red.bold.onWhite.description
        XCTAssertEqual(result, "\(esc)[1;31;47merr\(esc)[0m")
    }

    // MARK: - String interpolation composition

    func testInterpolationComposition() {
        let output = "\("Hello".red) \("world".blue)"
        XCTAssertEqual(output, "\(esc)[31mHello\(esc)[0m \(esc)[34mworld\(esc)[0m")
    }

    // MARK: - Idempotent modifiers

    func testDuplicateModifiersAreIdempotent() {
        let result = "x".bold.bold.bold.description
        XCTAssertEqual(result, "\(esc)[1mx\(esc)[0m")
    }

    // MARK: - Last color wins

    func testLastForegroundColorWins() {
        let result = "x".red.blue.description
        XCTAssertEqual(result, "\(esc)[34mx\(esc)[0m")
    }

    func testLastBackgroundColorWins() {
        let result = "x".onRed.onGreen.description
        XCTAssertEqual(result, "\(esc)[42mx\(esc)[0m")
    }

    // MARK: - ANSIColor codes

    func testANSIColorForegroundCodes() {
        for color in ANSIColor.allCases {
            XCTAssertEqual(color.foregroundCode, 30 + color.rawValue)
        }
    }

    func testANSIColorBackgroundCodes() {
        for color in ANSIColor.allCases {
            XCTAssertEqual(color.backgroundCode, 40 + color.rawValue)
        }
    }
}
