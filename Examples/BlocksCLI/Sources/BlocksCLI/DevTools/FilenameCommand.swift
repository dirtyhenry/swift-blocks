import ArgumentParser
import Blocks
import Foundation

/// Prints a safe filename for a title. The `slugify` command prints a URL slug instead.
struct FilenameCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "filename",
        abstract: "Print a safe filename for a title.",
        discussion: """
        The filename keeps accents, emoji and spaces. The filename is easy \
        to read. To get an identifier for a URL, use the slugify command.
        """
    )

    @Argument(help: "The title for the filename.")
    var title: String

    @Option(help: "The maximum length of the filename, in UTF-8 bytes. The default is 200.")
    var maxLength: Int?

    @Option(help: "An extension to add to the filename, such as md.")
    var `extension`: String?

    @Flag(help: "Also print the slug of the title, to compare the two results.")
    var compare = false

    mutating func run() throws {
        let stem = maxLength.map { title.sanitizedFilename(maxLength: $0) } ?? title.sanitizedFilename()
        let filename = `extension`.map { "\(stem).\($0)" } ?? stem

        if compare {
            print("filename: \(filename)")
            print("slug:     \(title.slugify())")
        } else {
            print(filename)
        }
    }
}
