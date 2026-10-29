#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

import Foundation

/// An interactive line editor with arrow key navigation and editing support.
///
/// Use ``CLIUtils/editLine(prompt:)`` to read a line with this editor.
enum LineEditor {
    /// The terminal that the editor reads keys from and writes to.
    ///
    /// The protocol lets the tests replace the real terminal.
    protocol Terminal {
        /// Reads one byte. Blocks until a byte is available.
        mutating func readByte() throws -> UInt8
        /// Reads one byte, or returns `nil` if no byte is available before the timeout.
        mutating func readByte(timeoutMilliseconds: Int32) -> UInt8?
        mutating func write(_ string: String)
        /// The width of the terminal, in columns.
        var columns: Int { get }
    }

    /// The time to wait for the next byte of an escape sequence after `ESC`.
    static let escapeTimeoutMilliseconds: Int32 = 100

    /// Reads one line from the given terminal.
    ///
    /// The terminal must already be in raw mode.
    static func readLine(prompt: String, terminal: inout some Terminal) throws -> String? {
        var session = Session(prompt: prompt)
        return try session.run(terminal: &terminal)
    }
}

// MARK: - Session

extension LineEditor {
    struct Session {
        /// The lines of the prompt before its last line. They are written one time only.
        let promptHead: String
        /// The last line of the prompt. It is written again at each redraw.
        let promptTail: String
        let promptWidth: Int
        var buffer = Buffer()

        init(prompt: String) {
            if let newline = prompt.lastIndex(of: "\n") {
                promptHead = String(prompt[...newline])
                promptTail = String(prompt[prompt.index(after: newline)...])
            } else {
                promptHead = ""
                promptTail = prompt
            }
            promptWidth = Buffer.displayWidth(ofVisible: promptTail)
        }

        // swiftlint:disable:next cyclomatic_complexity
        mutating func run(terminal: inout some Terminal) throws -> String? {
            terminal.write(promptHead.replacingOccurrences(of: "\n", with: "\r\n"))
            redraw(terminal: &terminal)

            while true {
                let byte = try terminal.readByte()

                switch byte {
                case 0x0D, 0x0A: // Enter
                    terminal.write("\r\n")
                    return buffer.toString()

                case 0x7F, 0x08: // Backspace
                    buffer.deleteBackward()

                case 0x04: // Ctrl-D
                    if buffer.isEmpty {
                        terminal.write("\r\n")
                        return nil
                    }
                    buffer.deleteForward()

                case 0x03: // Ctrl-C
                    terminal.write("^C\r\n")
                    throw LineEditorError.interrupted

                case 0x01: // Ctrl-A
                    buffer.moveToStart()

                case 0x05: // Ctrl-E
                    buffer.moveToEnd()

                case 0x02: // Ctrl-B
                    buffer.moveLeft()

                case 0x06: // Ctrl-F
                    buffer.moveRight()

                case 0x15: // Ctrl-U — kill line backward
                    buffer.killToStart()

                case 0x0B: // Ctrl-K — kill line forward
                    buffer.killToEnd()

                case 0x17: // Ctrl-W — delete the previous whitespace-delimited word
                    buffer.deleteWhitespaceWordBackward()

                case 0x1B: // ESC
                    try handleEscape(terminal: &terminal)

                case 0x20 ... 0x7E: // Printable ASCII
                    buffer.insert(Character(UnicodeScalar(byte)))

                case 0xC0 ... 0xF7: // UTF-8 leading byte
                    try buffer.insert(readUTF8(leadingByte: byte, terminal: &terminal))

                default:
                    continue
                }

                redraw(terminal: &terminal)
            }
        }

        // MARK: Escape Sequences

        // swiftlint:disable:next cyclomatic_complexity
        private mutating func handleEscape(terminal: inout some Terminal) throws {
            guard let next = terminal.readByte(timeoutMilliseconds: LineEditor.escapeTimeoutMilliseconds) else {
                return // Standalone ESC
            }

            switch next {
            case 0x5B: // ESC [ — CSI sequence
                try handleCSI(terminal: &terminal)

            case 0x4F: // ESC O — SS3 sequence, sent in application cursor mode
                switch try terminal.readByte() {
                case 0x44: buffer.moveLeft()
                case 0x43: buffer.moveRight()
                case 0x48: buffer.moveToStart()
                case 0x46: buffer.moveToEnd()
                default: break
                }

            case 0x62: // ESC b — Alt+Left
                buffer.moveWordLeft()

            case 0x66: // ESC f — Alt+Right
                buffer.moveWordRight()

            case 0x7F, 0x08: // ESC Backspace — Alt+Backspace
                buffer.deleteWordBackward()

            default:
                break
            }
        }

        private mutating func handleCSI(terminal: inout some Terminal) throws {
            let (parameters, final) = try readCSI(terminal: &terminal)
            let fields = parameters.split(separator: ";", omittingEmptySubsequences: false)
            // Alt (3), Ctrl (5) and Meta (9) move by word, as in most shells.
            let modifier = fields.count > 1 ? Int(fields[1]) ?? 1 : 1
            let movesByWord = [3, 5, 9].contains(modifier)

            switch final {
            case 0x44 where movesByWord: // Alt+Left
                buffer.moveWordLeft()
            case 0x44: // Left
                buffer.moveLeft()
            case 0x43 where movesByWord: // Alt+Right
                buffer.moveWordRight()
            case 0x43: // Right
                buffer.moveRight()
            case 0x48: // Home
                buffer.moveToStart()
            case 0x46: // End
                buffer.moveToEnd()
            case 0x7E: // ESC [ <code> ~
                handleTildeSequence(code: fields.first.map(String.init) ?? "")
            default:
                break
            }
        }

        /// Reads the rest of a CSI sequence: parameter bytes, intermediate bytes, then one final byte.
        ///
        /// Reading the whole sequence makes sure that no byte of an unknown sequence is inserted as text.
        private func readCSI(terminal: inout some Terminal) throws -> (parameters: String, final: UInt8) {
            var parameters = ""
            while true {
                let byte = try terminal.readByte()
                if (0x40 ... 0x7E).contains(byte) {
                    return (parameters, byte)
                }
                if (0x30 ... 0x3F).contains(byte) {
                    parameters.append(Character(UnicodeScalar(byte)))
                }
            }
        }

        private mutating func handleTildeSequence(code: String) {
            switch code {
            case "1", "7": buffer.moveToStart() // Home
            case "4", "8": buffer.moveToEnd() // End
            case "3": buffer.deleteForward() // Delete
            default: break
            }
        }

        private func readUTF8(leadingByte: UInt8, terminal: inout some Terminal) throws -> Character {
            let continuationCount = switch leadingByte {
            case 0xC0 ... 0xDF: 1
            case 0xE0 ... 0xEF: 2
            default: 3
            }

            var bytes = [leadingByte]
            for _ in 0 ..< continuationCount {
                try bytes.append(terminal.readByte())
            }

            return String(bytes: bytes, encoding: .utf8)?.first ?? "\u{FFFD}"
        }

        // MARK: Rendering

        /// Writes the last line of the prompt and the part of the buffer that fits in the terminal.
        ///
        /// If the line is wider than the terminal, the visible part scrolls horizontally to keep
        /// the cursor visible, so that the line never wraps.
        private func redraw(terminal: inout some Terminal) {
            let characters = buffer.characters
            let widths = characters.map(Buffer.displayWidth(of:))
            let available = max(terminal.columns - promptWidth - 1, 1)

            var start = 0
            var widthBeforeCursor = widths[..<buffer.cursor].reduce(0, +)
            while widthBeforeCursor > available, start < buffer.cursor {
                widthBeforeCursor -= widths[start]
                start += 1
            }

            var end = buffer.cursor
            var usedWidth = widthBeforeCursor
            while end < characters.count, usedWidth + widths[end] <= available {
                usedWidth += widths[end]
                end += 1
            }

            let visible = String(characters[start ..< end])
            let cursorColumn = promptWidth + widthBeforeCursor + 1
            // CR, write the line, erase to the end of the line, move the cursor.
            terminal.write("\r\(promptTail)\(visible)\u{1B}[K\r\u{1B}[\(cursorColumn)G")
        }
    }
}

// MARK: - Buffer

extension LineEditor {
    struct Buffer {
        private(set) var characters: [Character] = []
        private(set) var cursor: Int = 0

        var isEmpty: Bool {
            characters.isEmpty
        }

        var displayCursor: Int {
            characters[..<cursor].reduce(0) { $0 + Self.displayWidth(of: $1) }
        }

        /// Inserts a character at the cursor.
        ///
        /// The editor gets one Unicode scalar at a time, so a combining mark or the second half of
        /// an emoji sequence arrives as a separate character. The buffer groups the scalars again
        /// into extended grapheme clusters, so that one character on screen is one character in
        /// the buffer.
        mutating func insert(_ char: Character) {
            let prefix = String(characters[..<cursor]) + String(char)
            let line = prefix + String(characters[cursor...])
            characters = Array(line)
            cursor = min(prefix.count, characters.count)
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
            cursor = wordStart(before: cursor, isWordCharacter: Self.isAlphanumeric)
        }

        mutating func moveWordRight() {
            // Skip non-alphanumeric
            while cursor < characters.count, !Self.isAlphanumeric(characters[cursor]) {
                cursor += 1
            }
            // Skip word characters
            while cursor < characters.count, Self.isAlphanumeric(characters[cursor]) {
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

        /// Deletes the alphanumeric word before the cursor (Alt+Backspace).
        mutating func deleteWordBackward() {
            let start = wordStart(before: cursor, isWordCharacter: Self.isAlphanumeric)
            characters.removeSubrange(start ..< cursor)
            cursor = start
        }

        /// Deletes the whitespace-delimited word before the cursor (Ctrl-W).
        mutating func deleteWhitespaceWordBackward() {
            let start = wordStart(before: cursor) { !$0.isWhitespace }
            characters.removeSubrange(start ..< cursor)
            cursor = start
        }

        func toString() -> String {
            String(characters)
        }

        private func wordStart(before index: Int, isWordCharacter: (Character) -> Bool) -> Int {
            var index = index
            while index > 0, !isWordCharacter(characters[index - 1]) {
                index -= 1
            }
            while index > 0, isWordCharacter(characters[index - 1]) {
                index -= 1
            }
            return index
        }

        private static func isAlphanumeric(_ char: Character) -> Bool {
            char.isLetter || char.isNumber
        }

        // MARK: Display Width

        /// The number of terminal columns that a string uses, without its ANSI escape sequences.
        static func displayWidth(ofVisible string: String) -> Int {
            var visible = String.UnicodeScalarView()
            var iterator = string.unicodeScalars.makeIterator()
            while let scalar = iterator.next() {
                guard scalar == "\u{1B}" else {
                    visible.append(scalar)
                    continue
                }
                // Skip a CSI sequence (ESC [ ... final byte) or a two-byte escape sequence.
                guard iterator.next() == "[" else { continue }
                while let next = iterator.next(), !(0x40 ... 0x7E).contains(next.value) {}
            }
            return String(visible).reduce(0) { $0 + displayWidth(of: $1) }
        }

        /// The number of terminal columns that a character uses: 0, 1 or 2.
        static func displayWidth(of char: Character) -> Int {
            let scalars = char.unicodeScalars
            let isEmoji = scalars.contains { $0.properties.isEmojiPresentation }
                || (scalars.first?.properties.isEmoji == true && scalars.contains("\u{FE0F}"))
            if isEmoji {
                return 2
            }
            return min(scalars.reduce(0) { $0 + displayWidth(of: $1) }, 2)
        }

        static func displayWidth(of scalar: Unicode.Scalar) -> Int {
            switch scalar.properties.generalCategory {
            case .nonspacingMark, .enclosingMark, .format, .control:
                return 0
            default:
                break
            }

            let value = scalar.value
            if (0x1160 ... 0x11FF).contains(value) || // Hangul Jamo medial vowels and final consonants
                (0xFE00 ... 0xFE0F).contains(value)
            { // Variation selectors
                return 0
            }

            // East Asian Wide and Fullwidth characters take 2 columns
            if (0x1100 ... 0x115F).contains(value) || // Hangul Jamo initial consonants
                (0x2E80 ... 0x303E).contains(value) || // CJK Radicals, Kangxi, Ideographic
                (0x3041 ... 0x33BF).contains(value) || // Hiragana, Katakana, Bopomofo, CJK Compat
                (0x3400 ... 0x4DBF).contains(value) || // CJK Unified Extension A
                (0x4E00 ... 0x9FFF).contains(value) || // CJK Unified Ideographs
                (0xA000 ... 0xA4CF).contains(value) || // Yi
                (0xAC00 ... 0xD7AF).contains(value) || // Hangul Syllables
                (0xF900 ... 0xFAFF).contains(value) || // CJK Compatibility Ideographs
                (0xFE30 ... 0xFE6F).contains(value) || // CJK Compatibility Forms
                (0xFF01 ... 0xFF60).contains(value) || // Fullwidth Forms
                (0xFFE0 ... 0xFFE6).contains(value) || // Fullwidth Signs
                (0x20000 ... 0x2FFFD).contains(value) || // CJK Ext B-F, Compat Supplement
                (0x30000 ... 0x3FFFD).contains(value)
            { // CJK Ext G+
                return 2
            }
            return 1
        }
    }
}

// MARK: - Standard Terminal

#if canImport(Darwin) || canImport(Glibc)

#if canImport(Darwin)
private let systemWrite = Darwin.write
#else
private let systemWrite = Glibc.write
#endif

extension LineEditor {
    /// Reads a line from the standard input, which must be a terminal.
    static func readLine(prompt: String) throws -> String? {
        // Write the text that `print` keeps in its buffer before the editor writes directly.
        fflush(stdout)

        guard let terminalMode = TerminalMode.enableRaw() else {
            throw LineEditorError.readFailed
        }
        defer { terminalMode.restore() }

        var terminal = StandardTerminal()
        return try readLine(prompt: prompt, terminal: &terminal)
    }

    struct StandardTerminal: Terminal {
        func readByte() throws -> UInt8 {
            var byte: UInt8 = 0
            while true {
                let count = read(STDIN_FILENO, &byte, 1)
                if count == 1 {
                    return byte
                }
                if count < 0, errno == EINTR {
                    continue
                }
                throw LineEditorError.readFailed
            }
        }

        func readByte(timeoutMilliseconds: Int32) -> UInt8? {
            var descriptor = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
            guard poll(&descriptor, 1, timeoutMilliseconds) > 0 else { return nil }
            return try? readByte()
        }

        func write(_ string: String) {
            var string = string
            string.withUTF8 { buffer in
                var offset = 0
                while offset < buffer.count {
                    let count = systemWrite(STDOUT_FILENO, buffer.baseAddress! + offset, buffer.count - offset)
                    if count < 0, errno == EINTR {
                        continue
                    }
                    guard count > 0 else { return }
                    offset += count
                }
            }
        }

        var columns: Int {
            var size = winsize()
            guard ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size) == 0, size.ws_col > 0 else {
                return 80
            }
            return Int(size.ws_col)
        }
    }
}

#endif

// MARK: - Errors

/// The errors of ``CLIUtils/editLine(prompt:)``.
public enum LineEditorError: Error, CustomStringConvertible {
    /// The user pressed Ctrl-C.
    case interrupted
    /// The read from the standard input failed.
    case readFailed

    public var description: String {
        switch self {
        case .interrupted: "Interrupted"
        case .readFailed: "Failed to read from stdin"
        }
    }
}
