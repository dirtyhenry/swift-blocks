@testable import Blocks
import XCTest

final class LineEditorSessionTests: XCTestCase {
    // MARK: - Keys

    func testEnterReturnsTheLine() throws {
        XCTAssertEqual(try edit("abc\r"), "abc")
    }

    func testCtrlDOnEmptyLineReturnsNil() throws {
        XCTAssertNil(try edit("\u{04}"))
    }

    func testCtrlDOnNonEmptyLineDeletesForward() throws {
        XCTAssertEqual(try edit("abc\u{01}\u{04}\r"), "bc")
    }

    func testCtrlCThrows() {
        XCTAssertThrowsError(try edit("ab\u{03}")) { error in
            XCTAssertEqual(error as? LineEditorError, .interrupted)
        }
    }

    func testArrowKeys() throws {
        XCTAssertEqual(try edit("ac\u{1B}[Db\u{1B}[C!\r"), "abc!")
    }

    func testHomeAndEndInAllEncodings() throws {
        let homes = ["\u{1B}[H", "\u{1B}OH", "\u{1B}[1~", "\u{1B}[7~"]
        let ends = ["\u{1B}[F", "\u{1B}OF", "\u{1B}[4~", "\u{1B}[8~"]
        for (home, end) in zip(homes, ends) {
            XCTAssertEqual(try edit("b\(home)a\(end)c\r"), "abc", "\(home.debugDescription) \(end.debugDescription)")
        }
    }

    func testUnknownSequencesInsertNothing() throws {
        // Insert, Page Up, F5, Up arrow, Shift+Tab
        XCTAssertEqual(try edit("ab\u{1B}[2~\u{1B}[5~\u{1B}[15~\u{1B}[A\u{1B}[Z\r"), "ab")
    }

    func testDeleteKey() throws {
        XCTAssertEqual(try edit("abc\u{1B}[D\u{1B}[D\u{1B}[3~\r"), "ac")
    }

    func testWordMovementWithModifiers() throws {
        for left in ["\u{1B}b", "\u{1B}[1;3D", "\u{1B}[1;5D", "\u{1B}[1;9D"] {
            XCTAssertEqual(try edit("foo bar\(left)x\r"), "foo xbar", left.debugDescription)
        }
        for right in ["\u{1B}f", "\u{1B}[1;3C", "\u{1B}[1;5C"] {
            XCTAssertEqual(try edit("foo bar\u{01}\(right)x\r"), "foox bar", right.debugDescription)
        }
    }

    func testStandaloneEscapeIsIgnored() throws {
        XCTAssertEqual(try edit("ab\u{1B}", "c\r"), "abc")
    }

    func testCtrlWDeletesWhitespaceDelimitedWord() throws {
        XCTAssertEqual(try edit("cd ~/some/path\u{17}\r"), "cd ")
    }

    func testAltBackspaceDeletesAlphanumericWord() throws {
        XCTAssertEqual(try edit("cd ~/some/path\u{1B}\u{7F}\r"), "cd ~/some/")
    }

    func testUTF8Input() throws {
        XCTAssertEqual(try edit("café 你好 😀\r"), "café 你好 😀")
    }

    func testCombiningMarkStaysOnItsBaseCharacter() throws {
        XCTAssertEqual(try edit("e\u{0301}\u{1B}[Dx\r"), "xe\u{0301}")
    }

    // MARK: - Rendering

    func testCursorColumnAfterEmoji() {
        var terminal = ScriptedTerminal("😀")
        _ = try? LineEditor.readLine(prompt: "> ", terminal: &terminal)
        // 2 columns of prompt, 2 columns of emoji: the cursor is in column 5.
        XCTAssertTrue(terminal.output.hasSuffix("\u{1B}[5G"), terminal.output.debugDescription)
    }

    func testPromptStylesDoNotCountInTheCursorColumn() {
        var terminal = ScriptedTerminal("a")
        _ = try? LineEditor.readLine(prompt: "\u{1B}[1m\u{1B}[32m>\u{1B}[0m ", terminal: &terminal)
        XCTAssertTrue(terminal.output.hasSuffix("\u{1B}[4G"), terminal.output.debugDescription)
    }

    func testMultilinePromptWritesItsHeadOneTime() throws {
        var terminal = ScriptedTerminal("ab\r")
        XCTAssertEqual(try LineEditor.readLine(prompt: "Title\n> ", terminal: &terminal), "ab")
        XCTAssertEqual(terminal.output.components(separatedBy: "Title").count, 2)
        XCTAssertTrue(terminal.output.contains("\r> ab"))
    }

    func testLongLineScrollsInsteadOfWrapping() throws {
        var terminal = ScriptedTerminal(String(repeating: "x", count: 30) + "END")
        terminal.columns = 20
        _ = try? LineEditor.readLine(prompt: "> ", terminal: &terminal)
        let lastRedraw = try XCTUnwrap(terminal.redraws.last)
        // 20 columns - 2 for the prompt - 1 for the cursor = 17 visible characters.
        XCTAssertEqual(lastRedraw.text, "> " + String(repeating: "x", count: 14) + "END")
        XCTAssertEqual(lastRedraw.cursorColumn, 20)
    }

    func testLongLineShowsTheStartWhenTheCursorIsAtTheStart() throws {
        var terminal = ScriptedTerminal("START" + String(repeating: "x", count: 30) + "\u{01}")
        terminal.columns = 20
        _ = try? LineEditor.readLine(prompt: "> ", terminal: &terminal)
        let lastRedraw = try XCTUnwrap(terminal.redraws.last)
        XCTAssertEqual(lastRedraw.text, "> START" + String(repeating: "x", count: 12))
        XCTAssertEqual(lastRedraw.cursorColumn, 3)
    }

    // MARK: - Helpers

    /// Runs the editor on the given keys. Each argument is a separate burst of input:
    /// the escape timeout occurs between two bursts.
    private func edit(_ bursts: String...) throws -> String? {
        var terminal = ScriptedTerminal(bursts)
        return try LineEditor.readLine(prompt: "> ", terminal: &terminal)
    }
}

private struct ScriptedTerminal: LineEditor.Terminal {
    private var bursts: [[UInt8]]
    private(set) var output = ""
    var columns = 80

    init(_ input: String) {
        self.init([input])
    }

    init(_ bursts: [String]) {
        self.bursts = bursts.map { Array($0.utf8) }
    }

    /// The text and the cursor column of each redraw: `\r<text>ESC[K\rESC[<column>G`.
    var redraws: [(text: String, cursorColumn: Int)] {
        let pieces = output.components(separatedBy: "\u{1B}[K\r\u{1B}[")
        return zip(pieces, pieces.dropFirst()).map { before, after in
            (before.components(separatedBy: "\r").last ?? "", Int(after.prefix { $0.isNumber }) ?? 0)
        }
    }

    mutating func readByte() throws -> UInt8 {
        while let first = bursts.first, first.isEmpty {
            bursts.removeFirst()
        }
        guard !bursts.isEmpty else {
            throw LineEditorError.readFailed
        }
        return bursts[0].removeFirst()
    }

    mutating func readByte(timeoutMilliseconds _: Int32) -> UInt8? {
        guard let first = bursts.first, !first.isEmpty else {
            return nil
        }
        return bursts[0].removeFirst()
    }

    mutating func write(_ string: String) {
        output += string
    }
}
