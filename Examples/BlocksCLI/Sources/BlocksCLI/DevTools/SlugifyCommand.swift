import ArgumentParser
import Blocks
import Foundation

struct SlugifyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slugify",
        abstract: "Print a URL slug for a text.",
        discussion: """
        A slug is an identifier for a URL. It has only lowercase ASCII letters, digits and hyphens. \
        To get a filename that is easy to read, use the filename command.
        """
    )

    @Argument(help: "The input slug.")
    var inputToSlugify: String

    mutating func run() throws {
        print(inputToSlugify.slugify())
    }
}
