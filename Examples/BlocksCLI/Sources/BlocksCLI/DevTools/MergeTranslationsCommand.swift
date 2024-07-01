import ArgumentParser
import Foundation

typealias Translations = [String: String]

infix operator +: AdditionPrecedence

extension Translations {
    init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try JSONDecoder().decode(Translations.self, from: data)
    }

    func write(to outputURL: URL) throws {
        // Convert the dictionary into JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted])

        // Write the JSON data to the file
        try jsonData.write(to: outputURL)
    }

    static func + (lhs: Translations, rhs: Translations) -> Translations {
        rhs.reduce(into: lhs) { result, pair in
            result[pair.key] = pair.value
        }
    }
}

struct MergeTranslationsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "merge-translations",
        abstract: "Merge 2 translations files into a new file."
    )

    @Argument(help: "Path to first file.")
    var input1: String

    @Argument(help: "Path to second file.")
    var input2: String

    @Argument(help: "Path to output file.")
    var output: String

    @Flag var verbose = false

    mutating func run() throws {
        let translations1 = try Translations(contentsOf: URL(fileURLWithPath: input1))
        let translations2 = try Translations(contentsOf: URL(fileURLWithPath: input2))
        let outputTransations = translations1 + translations2
        try outputTransations.write(to: URL(fileURLWithPath: output))
    }
}
