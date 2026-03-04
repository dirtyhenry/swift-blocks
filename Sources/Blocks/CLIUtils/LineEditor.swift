#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

import Foundation

/// An interactive line editor with arrow key navigation and editing support.
///
/// Puts the terminal in raw mode to intercept escape sequences for cursor
/// movement, and provides readline-style keybindings (Ctrl-A, Ctrl-E, etc.).
public enum LineEditor {
    /// Reads a line of input with full editing support.
    ///
    /// Supports arrow keys, Home/End, Alt+arrow for word movement,
    /// Backspace, Delete, Ctrl-A/E/C/D, and UTF-8 input.
    ///
    /// - Parameter prompt: The prompt string displayed before the input area.
    /// - Returns: The entered string, or `nil` if the user pressed Ctrl-D on an empty line.
    /// - Throws: ``LineEditorError/interrupted`` if the user pressed Ctrl-C.
    public static func readLine(prompt: String) throws -> String? {
        TerminalMode.enableRaw()
        defer { TerminalMode.restore() }

        var buffer = Buffer()
        redraw(prompt: prompt, buffer: buffer)

        while true {
            let byte = try readByte()

            switch byte {
            case 0x0D, 0x0A: // Enter
                writeString("\n")
                return buffer.toString()

            case 0x7F, 0x08: // Backspace
                buffer.deleteBackward()
                redraw(prompt: prompt, buffer: buffer)

            case 0x04: // Ctrl-D
                if buffer.isEmpty {
                    writeString("\n")
                    return nil
                }

            case 0x03: // Ctrl-C
                writeString("^C\n")
                throw LineEditorError.interrupted

            case 0x01: // Ctrl-A
                buffer.moveToStart()
                redraw(prompt: prompt, buffer: buffer)

            case 0x05: // Ctrl-E
                buffer.moveToEnd()
                redraw(prompt: prompt, buffer: buffer)

            case 0x15: // Ctrl-U — kill line backward
                buffer.killToStart()
                redraw(prompt: prompt, buffer: buffer)

            case 0x0B: // Ctrl-K — kill line forward
                buffer.killToEnd()
                redraw(prompt: prompt, buffer: buffer)

            case 0x17: // Ctrl-W — delete word backward
                buffer.deleteWordBackward()
                redraw(prompt: prompt, buffer: buffer)

            case 0x1B: // ESC
                try handleEscape(buffer: &buffer, prompt: prompt)

            case 0x20...0x7E: // Printable ASCII
                buffer.insert(Character(UnicodeScalar(byte)))
                redraw(prompt: prompt, buffer: buffer)

            default:
                if byte >= 0xC0 { // UTF-8 leading byte
                    let char = try readUTF8(leadingByte: byte)
                    buffer.insert(char)
                    redraw(prompt: prompt, buffer: buffer)
                }
            }
        }
    }

    // MARK: - Escape Sequence Handling

    private static func handleEscape(buffer: inout Buffer, prompt: String) throws {
        guard let next = tryReadByte(timeoutMs: 50) else {
            return // Standalone ESC, ignore
        }

        switch next {
        case 0x5B: // ESC [  — CSI sequence
            try handleCSI(buffer: &buffer, prompt: prompt)

        case 0x62: // ESC b — Alt+Left (macOS Terminal)
            buffer.moveWordLeft()
            redraw(prompt: prompt, buffer: buffer)

        case 0x66: // ESC f — Alt+Right (macOS Terminal)
            buffer.moveWordRight()
            redraw(prompt: prompt, buffer: buffer)

        default:
            break
        }
    }

    private static func handleCSI(buffer: inout Buffer, prompt: String) throws {
        let byte = try readByte()

        switch byte {
        case 0x44: // ESC [ D — Left
            buffer.moveLeft()
            redraw(prompt: prompt, buffer: buffer)

        case 0x43: // ESC [ C — Right
            buffer.moveRight()
            redraw(prompt: prompt, buffer: buffer)

        case 0x48: // ESC [ H — Home
            buffer.moveToStart()
            redraw(prompt: prompt, buffer: buffer)

        case 0x46: // ESC [ F — End
            buffer.moveToEnd()
            redraw(prompt: prompt, buffer: buffer)

        case 0x33: // ESC [ 3 — possibly Delete
            let tilde = try readByte()
            if tilde == 0x7E { // ESC [ 3 ~ — Delete
                buffer.deleteForward()
                redraw(prompt: prompt, buffer: buffer)
            }

        case 0x31: // ESC [ 1 — possibly modified arrow
            let semi = try readByte()
            if semi == 0x3B { // semicolon
                let modifier = try readByte()
                let arrow = try readByte()
                if modifier == 0x33 { // Alt modifier (;3)
                    switch arrow {
                    case 0x44: // ESC [ 1;3 D — Alt+Left
                        buffer.moveWordLeft()
                        redraw(prompt: prompt, buffer: buffer)
                    case 0x43: // ESC [ 1;3 C — Alt+Right
                        buffer.moveWordRight()
                        redraw(prompt: prompt, buffer: buffer)
                    default:
                        break
                    }
                }
            }

        default:
            break
        }
    }

    // MARK: - I/O Helpers

    private static func readByte() throws -> UInt8 {
        var byte: UInt8 = 0
        let count = read(STDIN_FILENO, &byte, 1)
        guard count == 1 else {
            throw LineEditorError.readFailed
        }
        return byte
    }

    private static func tryReadByte(timeoutMs: Int32) -> UInt8? {
        var pfd = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
        let ready = poll(&pfd, 1, timeoutMs)
        guard ready > 0 else { return nil }
        var byte: UInt8 = 0
        let count = read(STDIN_FILENO, &byte, 1)
        return count == 1 ? byte : nil
    }

    private static func readUTF8(leadingByte: UInt8) throws -> Character {
        var bytes = [leadingByte]
        let continuationCount: Int
        if leadingByte & 0xE0 == 0xC0 { continuationCount = 1 }
        else if leadingByte & 0xF0 == 0xE0 { continuationCount = 2 }
        else if leadingByte & 0xF8 == 0xF0 { continuationCount = 3 }
        else { return "\u{FFFD}" }

        for _ in 0..<continuationCount {
            bytes.append(try readByte())
        }

        guard let str = String(bytes: bytes, encoding: .utf8), let char = str.first else {
            return "\u{FFFD}"
        }
        return char
    }

    private static func writeString(_ string: String) {
        string.utf8CString.withUnsafeBufferPointer { ptr in
            // Exclude the null terminator
            _ = write(STDOUT_FILENO, ptr.baseAddress, string.utf8.count)
        }
    }

    private static func redraw(prompt: String, buffer: Buffer) {
        let line = prompt + buffer.toString()
        let cursorCol = prompt.count + buffer.displayCursor
        // CR, write line, erase to EOL, reposition cursor
        writeString("\r\(line)\u{1B}[K\r\u{1B}[\(cursorCol + 1)G")
    }
}

// MARK: - Buffer

extension LineEditor {
    struct Buffer {
        private(set) var characters: [Character] = []
        private(set) var cursor: Int = 0

        var isEmpty: Bool { characters.isEmpty }

        var displayCursor: Int {
            characters[..<cursor].reduce(0) { $0 + displayWidth(of: $1) }
        }

        mutating func insert(_ char: Character) {
            characters.insert(char, at: cursor)
            cursor += 1
        }

        mutating func deleteBackward() {
            guard cursor > 0 else { return }
            cursor -= 1
            characters.remove(at: cursor)
        }

        mutating func deleteForward() {
            guard cursor < characters.count else { return }
            characters.remove(at: cursor)
        }

        mutating func moveLeft() {
            guard cursor > 0 else { return }
            cursor -= 1
        }

        mutating func moveRight() {
            guard cursor < characters.count else { return }
            cursor += 1
        }

        mutating func moveToStart() {
            cursor = 0
        }

        mutating func moveToEnd() {
            cursor = characters.count
        }

        mutating func moveWordLeft() {
            guard cursor > 0 else { return }
            cursor -= 1
            // Skip non-alphanumeric
            while cursor > 0, !characters[cursor].isLetter, !characters[cursor].isNumber {
                cursor -= 1
            }
            // Skip word characters
            while cursor > 0, characters[cursor - 1].isLetter || characters[cursor - 1].isNumber {
                cursor -= 1
            }
        }

        mutating func moveWordRight() {
            guard cursor < characters.count else { return }
            // Skip non-alphanumeric
            while cursor < characters.count, !characters[cursor].isLetter, !characters[cursor].isNumber {
                cursor += 1
            }
            // Skip word characters
            while cursor < characters.count, characters[cursor].isLetter || characters[cursor].isNumber {
                cursor += 1
            }
        }

        mutating func killToStart() {
            characters.removeFirst(cursor)
            cursor = 0
        }

        mutating func killToEnd() {
            characters.removeSubrange(cursor...)
        }

        mutating func deleteWordBackward() {
            let original = cursor
            moveWordLeft()
            characters.removeSubrange(cursor..<original)
        }

        func toString() -> String {
            String(characters)
        }

        private func displayWidth(of char: Character) -> Int {
            guard let scalar = char.unicodeScalars.first else { return 1 }
            let v = scalar.value
            // East Asian Wide and Fullwidth characters take 2 columns
            if (0x1100...0x115F).contains(v) || // Hangul Jamo
                (0x2E80...0x303E).contains(v) || // CJK Radicals, Kangxi, Ideographic
                (0x3041...0x33BF).contains(v) || // Hiragana, Katakana, Bopomofo, CJK Compat
                (0x3400...0x4DBF).contains(v) || // CJK Unified Extension A
                (0x4E00...0x9FFF).contains(v) || // CJK Unified Ideographs
                (0xA000...0xA4CF).contains(v) || // Yi
                (0xAC00...0xD7AF).contains(v) || // Hangul Syllables
                (0xF900...0xFAFF).contains(v) || // CJK Compatibility Ideographs
                (0xFE30...0xFE6F).contains(v) || // CJK Compatibility Forms
                (0xFF01...0xFF60).contains(v) || // Fullwidth Forms
                (0xFFE0...0xFFE6).contains(v) || // Fullwidth Signs
                (0x20000...0x2FFFD).contains(v) || // CJK Ext B-F, Compat Supplement
                (0x30000...0x3FFFD).contains(v) { // CJK Ext G+
                return 2
            }
            return 1
        }
    }
}

// MARK: - Errors

public enum LineEditorError: Error, CustomStringConvertible {
    case interrupted
    case readFailed

    public var description: String {
        switch self {
        case .interrupted: "Interrupted"
        case .readFailed: "Failed to read from stdin"
        }
    }
}
