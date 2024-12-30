import ArgumentParser
import Blocks
import Foundation

struct LintCopyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lint-copy",
        abstract: "Fix common mistakes in copy typography."
    )

    @Argument(help: "The input to lint.")
    var input: String

    mutating func run() throws {
        print(CopyUtils.lint(input: input))
    }
}
