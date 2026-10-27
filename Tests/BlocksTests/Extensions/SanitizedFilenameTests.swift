import Blocks
import XCTest

final class SanitizedFilenameTests: XCTestCase {
    // MARK: - Forbidden characters

    func testForbiddenCharactersBecomeSpaces() {
        XCTAssertEqual("Swift: Codable / JSON #1".sanitizedFilename(), "Swift Codable JSON 1")
        XCTAssertEqual(#"a\b^c[d]e|f*g"h<i>j?k"#.sanitizedFilename(), "a b c d e f g h i j k")
    }

    func testForbiddenCharacterFollowedByCombiningMarksIsReplaced() {
        XCTAssertEqual("a/\u{301}b".sanitizedFilename(), "a b")
        XCTAssertEqual("Key:\u{301}value".sanitizedFilename(), "Key value")
        XCTAssertEqual("Item #️⃣ 1".sanitizedFilename(), "Item 1")
    }

    func testInvisibleAndBidiCharactersAreRemoved() {
        XCTAssertEqual("\u{200B}".sanitizedFilename(), "Untitled")
        XCTAssertEqual("\u{FEFF}Note\u{200E}\u{202E}txt".sanitizedFilename(), "Notetxt")
        // Zero-width joiners in emoji sequences stay.
        XCTAssertEqual("👨‍👩‍👧".sanitizedFilename(), "👨‍👩‍👧")
    }

    func testControlCharactersBecomeSpaces() {
        XCTAssertEqual("a\u{0}b\u{7F}c\u{85}d".sanitizedFilename(), "a b c d")
    }

    // MARK: - Whitespace and dots

    func testWhitespaceRunsAreCollapsed() {
        XCTAssertEqual("  Hello \n\t world\u{A0}\u{A0}again  ".sanitizedFilename(), "Hello world again")
    }

    func testLeadingAndTrailingDotsAreTrimmed() {
        XCTAssertEqual(". .hidden note... ".sanitizedFilename(), "hidden note")
        XCTAssertEqual("v1.2 notes".sanitizedFilename(), "v1.2 notes")
        XCTAssertEqual(".\u{301}abc.\u{301}".sanitizedFilename(), "abc")
    }

    // MARK: - Unicode

    func testUnicodeLettersAccentsEmojiAndSpacesAreKept() {
        let title = "Café ☕️ notes — été, 日本語 & 👨‍👩‍👧"
        XCTAssertEqual(title.sanitizedFilename(), title)
    }

    func testResultIsNormalizedToNFC() {
        XCTAssertEqual("Cafe\u{301}".sanitizedFilename().unicodeScalars.count, 4)
        XCTAssertEqual(String(repeating: "e\u{301}", count: 150).sanitizedFilename().utf8.count, 200)
    }

    // MARK: - Length

    func testLengthIsCappedAt200UTF8BytesByDefault() {
        XCTAssertEqual(String(repeating: "a", count: 300).sanitizedFilename(), String(repeating: "a", count: 200))
        XCTAssertEqual(String(repeating: "é", count: 150).sanitizedFilename(), String(repeating: "é", count: 100))
    }

    func testLengthCapDoesNotSplitGraphemeClusters() {
        // The family emoji uses 18 UTF-8 bytes.
        XCTAssertEqual("ab👨‍👩‍👧".sanitizedFilename(maxLength: 10), "ab")
        XCTAssertEqual("🇫🇷🇫🇷".sanitizedFilename(maxLength: 10), "🇫🇷")
    }

    func testLengthCapTrimsTrailingSpacesAndDots() {
        XCTAssertEqual("Hello world".sanitizedFilename(maxLength: 6), "Hello")
        XCTAssertEqual("Hello. world".sanitizedFilename(maxLength: 7), "Hello")
    }

    // MARK: - Fallback

    func testEmptyResultUsesFallback() {
        XCTAssertEqual("  ... // ##  ".sanitizedFilename(), "Untitled")
        XCTAssertEqual("".sanitizedFilename(fallback: "Note"), "Note")
    }

    func testFallbackIsSanitizedAndNeverEmpty() {
        XCTAssertEqual("".sanitizedFilename(fallback: "a/b: c"), "a b c")
        XCTAssertEqual("".sanitizedFilename(fallback: ""), "Untitled")
        XCTAssertEqual("".sanitizedFilename(fallback: " .. "), "Untitled")
        XCTAssertEqual("abc".sanitizedFilename(maxLength: 0), "Untitled")
    }
}
