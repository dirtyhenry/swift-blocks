import ArgumentParser
import Blocks
import Foundation

/// Prints a new Markdown note. `FrontMatterEncoder` writes the front matter block at the start of the note.
struct NewNoteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new-note",
        abstract: "Print a new Markdown note with front matter.",
        discussion: """
        FrontMatterEncoder writes the front matter. Titles and tags can contain quotation marks, \
        colons, # or emoji.
        """
    )

    struct FrontMatter: Encodable {
        let title: String
        let date: PlainDate
        let tags: [String]
        let source: URL?
        let draft: Bool
    }

    @Argument(help: "The title of the note.")
    var title: String

    @Option(help: "The date of the note, as YYYY-MM-DD. The default is today.")
    var date: String?

    @Option(name: .customLong("tag"), help: "A tag. Use this option again to add more tags.")
    var tags: [String] = []

    @Option(help: "The URL of the source of the note.")
    var source: String?

    @Flag(help: "Mark the note as a draft.")
    var draft = false

    mutating func run() throws {
        let frontMatter = try FrontMatter(
            title: title,
            date: date.map(parseDate) ?? PlainDate(date: Date()),
            tags: tags,
            source: source.map(parseURL),
            draft: draft
        )
        try print(FrontMatterEncoder().encode(frontMatter))
        print("# \(title)")
    }

    private func parseDate(_ string: String) throws -> PlainDate {
        guard let date = PlainDate(from: string) else {
            throw ValidationError("The date is not a valid YYYY-MM-DD date: \(string)")
        }
        return date
    }

    private func parseURL(_ string: String) throws -> URL {
        guard let url = URL(string: string), url.scheme != nil else {
            throw ValidationError("The source is not a valid URL: \(string)")
        }
        return url
    }
}
