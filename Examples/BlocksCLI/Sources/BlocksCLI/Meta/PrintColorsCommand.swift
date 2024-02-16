import ArgumentParser
import Foundation
import Blocks

struct PrintColorsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
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
    }
}
