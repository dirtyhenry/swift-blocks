import ArgumentParser
import Blocks
import Foundation

struct PrintColorsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "print-colors",
        abstract: "A test tool for CLIUtils."
    )

    mutating func run() throws {
        CLIUtils.write(message: "This is the default.")

        CLIUtils.write(message: "🖤 This should be black.", foreground: .black)
        CLIUtils.write(message: "❤️ This should be red.", foreground: .red)
        CLIUtils.write(message: "💚 This should be green.", foreground: .green)
        CLIUtils.write(message: "💛 This should be yellow.", foreground: .yellow)
        CLIUtils.write(message: "💙 This should be blue.", foreground: .blue)
        CLIUtils.write(message: "💜 This should be magenta.", foreground: .magenta)
        CLIUtils.write(message: "🩵 This should be cyan.", foreground: .cyan)
        CLIUtils.write(message: "🤍 This should be white.", foreground: .white)

        CLIUtils.write(message: "🖤 This should be black.", background: .black)
        CLIUtils.write(message: "❤️ This should be red.", background: .red)
        CLIUtils.write(message: "💚 This should be green.", background: .green)
        CLIUtils.write(message: "💛 This should be yellow.", background: .yellow)
        CLIUtils.write(message: "💙 This should be blue.", background: .blue)
        CLIUtils.write(message: "💜 This should be magenta.", background: .magenta)
        CLIUtils.write(message: "🩵 This should be cyan.", background: .cyan)
        CLIUtils.write(message: "🤍 This should be white.", background: .white)

        print("\u{001B}[38;2;255;82;197;48;2;155;106;0mHello")

        // Composable StyledText API
        print("")
        print("--- StyledText API ---")
        print("\("Hello".red) \("world".blue)")
        print("\("Error".red.bold): something went wrong")
        print("\("WARNING".yellow.onRed) check this")
        print("\("bold".bold) \("dim".dim) \("italic".italic) \("underline".underline) \("strikethrough".strikethrough)")
        CLIUtils.write(parts: "Status: ".white.bold, "OK".green.bold)

        if isatty(STDIN_FILENO) != 0 {
            let choice = try CLIUtils.interactiveShell(
                "command -v gum >/dev/null && gum choose \"fix\" \"feat\" \"docs\" \"style\" \"refactor\" \"test\" \"chore\" \"revert\"",
                captureOutput: true
            )
            print("You chose: \(choice ?? "nothing (gum not installed)")")
        }
    }
}
