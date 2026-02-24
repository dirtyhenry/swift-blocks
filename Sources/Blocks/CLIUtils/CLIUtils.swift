import Foundation

public enum CLIUtils {
    /// Reads a line of input from the user, optionally in a secure manner.
    ///
    /// This method provides a way to get user input from the command line.
    /// It can either use `getpass` for secure input (e.g., for passwords, where the input is hidden)
    /// or Swift's `readLine` for regular input.
    ///
    /// - Parameters:
    ///    - prompt: The message displayed to the user, prompting them for input.
    ///    - secure: A boolean value indicating whether the input should be read securely (hidden from the terminal).
    ///              If `true`, `getpass` is used; otherwise, `readLine` is used.
    ///
    /// - Returns: A String containing the user's input if successful. Returns `nil` if an error occurred,
    ///            if the user provided no input, or if secure input is not supported.
    public static func readLine(prompt: String, secure: Bool) -> String? {
        if secure {
            return String(cString: getpass(prompt))
        } else {
            print(prompt)
            return Swift.readLine()
        }
    }

    /// Writes a message to the console with optional foreground and background colors.
    ///
    /// This method allows you to print messages to the console with custom colors, enhancing the visual
    /// presentation of your command-line interface.
    ///
    /// - Parameters:
    ///   - message: The string message to be displayed.
    ///   - foreground: The desired foreground color for the message. Defaults to `.none` (no color).
    ///   - background: The desired background color for the message. Defaults to `.none` (no color).
    public static func write(
        message: String, foreground: CLIColor = .none, background: CLIColor = .none
    ) {
        print("\(foreground.foreground)\(background.background)\(message)\(CLIColor.reset)")
    }

    /// Writes composed styled text parts to the console on a single line.
    ///
    /// - Parameter parts: One or more ``StyledText`` values to concatenate and print.
    public static func write(parts: StyledText...) {
        print(parts.map(\.description).joined())
    }

    /// Represents the available colors for console output.
    public enum CLIColor {
        /// Represents the absence of color (default terminal color).
        case none

        case black
        case red
        case green
        case yellow
        case blue
        case magenta
        case cyan
        case white

        /// The ANSI escape code for setting the foreground color.
        var foreground: String {
            switch self {
            case .none:
                "\u{001B}[39m" // Default foreground color
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

        /// The ANSI escape code for setting the background color.
        var background: String {
            switch self {
            case .none:
                "\u{001B}[49m" // Default background color
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

        /// The ANSI escape code for resetting the color to the default.
        static let reset = "\u{001B}[0m"
    }
}

#if os(macOS)
public extension CLIUtils {
    /// Executes a shell command and returns the output as a string.
    ///
    /// This method provides a convenient way to run shell commands directly from your Swift code.
    /// It captures both standard output and standard error, returning them as a single string.
    ///
    /// - Important: This function is only available on macOS.
    ///
    /// - Parameter command: The shell command to execute (e.g., "ls -l", "pwd").
    /// - Returns: The combined standard output and standard error of the executed command.
    /// - Throws:
    ///   - `SimpleMessageError` if the command could not be executed or if the output could not be read as UTF-8.
    ///   - `SimpleMessageError` if the command exited with a non-zero status code, indicating an error.
    ///
    /// - Note: Heavily inspired by [this SO question][1] and by [_Building macOS Utility Apps with Command Line
    ///   Tools_][2] by Karin Prater.
    ///
    /// [1]: https://stackoverflow.com/a/50035059/455016
    /// [2]: https://www.swiftyplace.com/blog/building-macos-utiltiy-apps
    @discardableResult static func shell(_ command: String) throws -> String {
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
            throw SimpleMessageError(
                message: "Command failed with status \(process.terminationStatus)"
            )
        }

        return output
    }

    /// Executes a shell command interactively, inheriting the parent's terminal.
    ///
    /// The child process shares the parent's stdin and stderr directly,
    /// preserving colors, formatting, and interactive input (e.g., `fzf`, `gum`).
    ///
    /// When `captureOutput` is `false` (the default), stdout is also inherited
    /// and the method returns `nil`. When `captureOutput` is `true`, stdout is
    /// redirected to a pipe so the result can be read — this is how you capture
    /// the selection from tools like `gum choose` that render their UI on stderr
    /// and write the result to stdout.
    ///
    /// - Important: This function is only available on macOS.
    ///
    /// - Parameters:
    ///   - command: The shell command to execute.
    ///   - captureOutput: If `true`, captures and returns the command's stdout.
    /// - Returns: The captured stdout when `captureOutput` is `true`, otherwise `nil`.
    /// - Throws: `SimpleMessageError` if the command exited with a non-zero status code.
    @discardableResult static func interactiveShell(
        _ command: String,
        captureOutput: Bool = false
    ) throws -> String? {
        var pid: pid_t = 0
        var fileActions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fileActions)
        defer { posix_spawn_file_actions_destroy(&fileActions) }

        // Always inherit stdin and stderr for interactive TTY access.
        posix_spawn_file_actions_addinherit_np(&fileActions, STDIN_FILENO)
        posix_spawn_file_actions_addinherit_np(&fileActions, STDERR_FILENO)

        var pipeFDs: [Int32] = [0, 0]
        if captureOutput {
            pipe(&pipeFDs)
            // Redirect the child's stdout to the write end of the pipe.
            posix_spawn_file_actions_adddup2(&fileActions, pipeFDs[1], STDOUT_FILENO)
            posix_spawn_file_actions_addclose(&fileActions, pipeFDs[0])
            posix_spawn_file_actions_addclose(&fileActions, pipeFDs[1])
        } else {
            posix_spawn_file_actions_addinherit_np(&fileActions, STDOUT_FILENO)
        }

        let args: [String?] = ["/bin/zsh", "-c", command, nil]
        let argv = args.map { $0.flatMap { strdup($0) } }
        defer { argv.forEach { free($0) } }

        let spawnResult = posix_spawn(&pid, "/bin/zsh", &fileActions, nil, argv, environ)

        if captureOutput {
            // Close the write end in the parent so reads can reach EOF.
            close(pipeFDs[1])
        }

        guard spawnResult == 0 else {
            if captureOutput { close(pipeFDs[0]) }
            throw SimpleMessageError(
                message: "Failed to spawn process: \(spawnResult)"
            )
        }

        var output: String?
        if captureOutput {
            let handle = FileHandle(fileDescriptor: pipeFDs[0], closeOnDealloc: true)
            let data = handle.readDataToEndOfFile()
            output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var status: Int32 = 0
        waitpid(pid, &status, 0)

        let exitCode = (status >> 8) & 0xFF
        guard exitCode == 0 else {
            throw SimpleMessageError(
                message: "Command failed with status \(exitCode)"
            )
        }

        return output
    }
}
#endif
