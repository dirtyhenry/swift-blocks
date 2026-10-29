#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if canImport(Darwin) || canImport(Glibc)

/// The raw mode of the terminal on the standard input.
///
/// In raw mode, the terminal sends each key to the program immediately, without echo and without
/// signals for Ctrl-C and Ctrl-Z.
struct TerminalMode {
    private let original: termios

    /// Puts the terminal in raw mode and returns the mode to restore.
    ///
    /// Returns `nil` if the standard input is not a terminal.
    static func enableRaw() -> TerminalMode? {
        var original = termios()
        guard tcgetattr(STDIN_FILENO, &original) == 0 else {
            return nil
        }

        var raw = original
        raw.c_lflag &= ~tcflag_t(ICANON | ECHO | ISIG | IEXTEN)
        // Let Ctrl-S and Ctrl-Q reach the editor instead of stopping the output.
        raw.c_iflag &= ~tcflag_t(IXON)

        withUnsafeMutablePointer(to: &raw.c_cc) { ptr in
            ptr.withMemoryRebound(to: cc_t.self, capacity: Int(NCCS)) { controlCharacters in
                controlCharacters[Int(VMIN)] = 1
                controlCharacters[Int(VTIME)] = 0
            }
        }

        // `TCSANOW` keeps the keys that the user typed before the prompt. `TCSAFLUSH` discards them.
        guard tcsetattr(STDIN_FILENO, TCSANOW, &raw) == 0 else {
            return nil
        }

        return TerminalMode(original: original)
    }

    /// Restores the mode that the terminal had before ``enableRaw()``.
    ///
    /// The keys that the user typed after the line stay available for the next read.
    func restore() {
        var original = original
        tcsetattr(STDIN_FILENO, TCSANOW, &original)
    }
}

#endif
