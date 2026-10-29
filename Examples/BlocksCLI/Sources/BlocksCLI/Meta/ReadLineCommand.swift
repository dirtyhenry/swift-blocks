import ArgumentParser
import Blocks
import Foundation

struct ReadLineCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "readline",
        abstract: "Read a line that you can edit with the arrow keys and the usual shell keys."
    )

    @Option(help: "The text to show before the input.")
    var prompt = "Enter some text: "

    mutating func run() throws {
        guard let input = try CLIUtils.editLine(prompt: prompt) else {
            print("No input was entered.")
            return
        }
        print("You entered: \(input)")
    }
}
