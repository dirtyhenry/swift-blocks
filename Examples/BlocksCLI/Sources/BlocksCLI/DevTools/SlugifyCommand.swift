import ArgumentParser
import Blocks
import Foundation

struct SlugifyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slugify",
        abstract: "Outputs a slug for the input."
    )

    @Argument(help: "The input slug.")
    var inputToSlugify: String

    mutating func run() throws {
        print(inputToSlugify.slugify())
    }
}
