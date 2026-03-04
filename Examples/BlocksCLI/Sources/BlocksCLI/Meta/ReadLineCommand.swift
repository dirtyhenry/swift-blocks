import ArgumentParser
import Blocks
import Foundation

struct ReadLineCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "readline",
        abstract: "Read a line of input from the cli."
    )

    @Flag(help: "Read input securely (hidden from terminal).")
    var secure = false

    mutating func run() throws {
        if secure {
            guard let input = CLIUtils.readLine(prompt: "Enter secret input (hidden): ", secure: true) else {
                print("No input was entered.")
                return
            }
            print("You entered: \(input)")
        } else {
            guard let input = try CLIUtils.editLine(prompt: "Enter some text: ") else {
                print("No input was entered.")
                return
            }
            print("You entered: \(input)")
        }
    }
}
