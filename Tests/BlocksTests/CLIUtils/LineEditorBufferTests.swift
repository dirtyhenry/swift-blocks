@testable import Blocks
import XCTest

final class LineEditorBufferTests: XCTestCase {
    // MARK: - Insert

    func testInsertAppends() {
        var buf = LineEditor.Buffer()
        buf.insert("a")
        buf.insert("b")
        buf.insert("c")
        XCTAssertEqual(buf.toString(), "abc")
        XCTAssertEqual(buf.cursor, 3)
    }

    func testInsertAtMiddle() {
        var buf = LineEditor.Buffer()
        buf.insert("a")
        buf.insert("c")
        buf.moveLeft()
        buf.insert("b")
        XCTAssertEqual(buf.toString(), "abc")
        XCTAssertEqual(buf.cursor, 2)
    }

    // MARK: - Delete

    func testDeleteBackward() {
        var buf = buffer("abc")
        buf.deleteBackward()
        XCTAssertEqual(buf.toString(), "ab")
        XCTAssertEqual(buf.cursor, 2)
    }

    func testDeleteBackwardAtStart() {
        var buf = buffer("abc")
        buf.moveToStart()
        buf.deleteBackward()
        XCTAssertEqual(buf.toString(), "abc")
        XCTAssertEqual(buf.cursor, 0)
    }

    func testDeleteForward() {
        var buf = buffer("abc")
        buf.moveToStart()
        buf.deleteForward()
        XCTAssertEqual(buf.toString(), "bc")
        XCTAssertEqual(buf.cursor, 0)
    }

    func testDeleteForwardAtEnd() {
        var buf = buffer("abc")
        buf.deleteForward()
        XCTAssertEqual(buf.toString(), "abc")
        XCTAssertEqual(buf.cursor, 3)
    }

    // MARK: - Movement

    func testMoveLeftAndRight() {
        var buf = buffer("abc")
        buf.moveLeft()
        XCTAssertEqual(buf.cursor, 2)
        buf.moveRight()
        XCTAssertEqual(buf.cursor, 3)
    }

    func testMoveLeftAtStartIsNoop() {
        var buf = buffer("abc")
        buf.moveToStart()
        buf.moveLeft()
        XCTAssertEqual(buf.cursor, 0)
    }

    func testMoveRightAtEndIsNoop() {
        var buf = buffer("abc")
        buf.moveRight()
        XCTAssertEqual(buf.cursor, 3)
    }

    func testMoveToStartAndEnd() {
        var buf = buffer("hello")
        buf.moveToStart()
        XCTAssertEqual(buf.cursor, 0)
        buf.moveToEnd()
        XCTAssertEqual(buf.cursor, 5)
    }

    // MARK: - Word Movement

    func testMoveWordLeft() {
        var buf = buffer("hello world")
        buf.moveWordLeft()
        XCTAssertEqual(buf.cursor, 6)
    }

    func testMoveWordLeftSkipsSpaces() {
        var buf = buffer("hello   world")
        buf.moveWordLeft()
        XCTAssertEqual(buf.cursor, 8)
    }

    func testMoveWordLeftAtStart() {
        var buf = buffer("hello")
        buf.moveToStart()
        buf.moveWordLeft()
        XCTAssertEqual(buf.cursor, 0)
    }

    func testMoveWordRight() {
        var buf = buffer("hello world")
        buf.moveToStart()
        buf.moveWordRight()
        XCTAssertEqual(buf.cursor, 5)
    }

    func testMoveWordRightSkipsSpaces() {
        var buf = buffer("hello   world")
        buf.moveToStart()
        buf.moveWordRight()
        XCTAssertEqual(buf.cursor, 5)
    }

    func testMoveWordRightAtEnd() {
        var buf = buffer("hello")
        buf.moveWordRight()
        XCTAssertEqual(buf.cursor, 5)
    }

    // MARK: - Kill

    func testKillToStart() {
        var buf = buffer("hello world")
        buf.moveWordLeft()
        buf.killToStart()
        XCTAssertEqual(buf.toString(), "world")
        XCTAssertEqual(buf.cursor, 0)
    }

    func testKillToEnd() {
        var buf = buffer("hello world")
        buf.moveToStart()
        buf.moveWordRight()
        buf.killToEnd()
        XCTAssertEqual(buf.toString(), "hello")
        XCTAssertEqual(buf.cursor, 5)
    }

    func testDeleteWordBackward() {
        var buf = buffer("hello world")
        buf.deleteWordBackward()
        XCTAssertEqual(buf.toString(), "hello ")
        XCTAssertEqual(buf.cursor, 6)
    }

    // MARK: - Display Width

    func testDisplayCursorASCII() {
        let buf = buffer("hello")
        XCTAssertEqual(buf.displayCursor, 5)
    }

    func testDisplayCursorCJK() {
        let buf = buffer("你好")
        XCTAssertEqual(buf.displayCursor, 4)
    }

    func testDisplayCursorMixed() {
        // "hi你" = 2 ASCII (width 1 each) + 1 CJK (width 2) = 4
        let buf = buffer("hi你")
        XCTAssertEqual(buf.displayCursor, 4)
    }

    // MARK: - Empty Buffer

    func testEmptyBuffer() {
        let buf = LineEditor.Buffer()
        XCTAssertTrue(buf.isEmpty)
        XCTAssertEqual(buf.toString(), "")
        XCTAssertEqual(buf.cursor, 0)
    }

    // MARK: - Helpers

    private func buffer(_ string: String) -> LineEditor.Buffer {
        var buf = LineEditor.Buffer()
        for char in string {
            buf.insert(char)
        }
        return buf
    }
}
