import Foundation

public enum CLIUtils {
    /// Reads a line of input from the user.
    ///
    /// This method is a proxy to either `getpass` for secure input, or Swift's `readLine` otherwise.
    ///
    /// - Parameters:
    ///    - prompt: The prompt for the user's input.
    ///    - secure: A boolean value that determines whether the input should be read securely.
    ///
    /// - Returns: A String containing the user input if successful, or nil if an error occurred or if there is no available input.
    public static func readLine(prompt: String, secure: Bool) -> String? {
        if secure {
            return String(cString: getpass(prompt))
        } else {
            print(prompt)
            return Swift.readLine()
        }
    }

    public static func write(
        message: String, foreground: CLIColor = .none, background: CLIColor = .none
    ) {
        print("\(foreground.foreground)\(background.background)\(message)\(CLIColor.reset)")
    }

    public enum CLIColor {
        case none

        case black
        case red
        case green
        case yellow
        case blue
        case magenta
        case cyan
        case white

        var foreground: String {
            switch self {
            case .none:
                "\u{001B}[39m"
            case .black:
                "\u{001B}[30m"
            case .red:
                "\u{001B}[31m"
            case .green:
                "\u{001B}[32m"
            case .yellow:
                "\u{001B}[33m"
            case .blue:
                "\u{001B}[34m"
            case .magenta:
                "\u{001B}[35m"
            case .cyan:
                "\u{001B}[36m"
            case .white:
                "\u{001B}[37m"
            }
        }

        var background: String {
            switch self {
            case .none:
                "\u{001B}[49m"
            case .black:
                "\u{001B}[40m"
            case .red:
                "\u{001B}[41m"
            case .green:
                "\u{001B}[42m"
            case .yellow:
                "\u{001B}[43m"
            case .blue:
                "\u{001B}[44m"
            case .magenta:
                "\u{001B}[45m"
            case .cyan:
                "\u{001B}[46m"
            case .white:
                "\u{001B}[47m"
            }
        }

        static let reset = "\u{001B}[0m"
    }
}

#if os(macOS)
    extension CLIUtils {
        /// Executes a shell command and returns the output.
        ///
        /// 📜 Heavily inspired by [this SO question][1] and by [_Building macOS Utility Apps with Command Line
        /// Tools_][2] by Karin Prater.
        ///
        /// [1]: https://stackoverflow.com/a/50035059/455016
        /// [2]: https://www.swiftyplace.com/blog/building-macos-utiltiy-apps
        ///
        /// - Parameter command: The shell command to execute.
        /// - Returns: Output of the executed shell command.
        public static func shell(_ command: String) throws -> String {
            let process = Process()
            let pipe = Pipe()

            process.standardOutput = pipe
            process.standardError = pipe
            process.arguments = ["-c", command]
            process.launchPath = "/bin/zsh"
            process.standardInput = nil
            try process.run()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                throw SimpleMessageError(message: "Could not read UTF8 output from command.")
            }

            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                throw SimpleMessageError(message: "Command failed with status \(process.terminationStatus)")
            }

            return output
        }
    }
#endif
