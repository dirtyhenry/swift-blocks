#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

enum TerminalMode {
    nonisolated(unsafe) private static var original: termios?

    static func enableRaw() {
        var raw = termios()
        tcgetattr(STDIN_FILENO, &raw)
        original = raw

        raw.c_lflag &= ~tcflag_t(ICANON | ECHO | ISIG | IEXTEN)

        withUnsafeMutablePointer(to: &raw.c_cc) { ptr in
            ptr.withMemoryRebound(to: UInt8.self, capacity: Int(NCCS)) { cc in
                cc[Int(VMIN)] = 1
                cc[Int(VTIME)] = 0
            }
        }

        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    }

    static func restore() {
        guard var saved = original else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &saved)
        original = nil
    }
}
