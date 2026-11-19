import ArgumentParser
import Foundation

/// Benchmarks the on-device Foundation Models framework on everyday text tasks.
struct FMBenchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fm-bench",
        abstract: "Measure what the on-device model can classify, tag, summarize, extract and rewrite.",
        subcommands: Self.subcommands,
        defaultSubcommand: FMBenchReportCommand.self
    )

    private static var subcommands: [ParsableCommand.Type] {
        var commands: [ParsableCommand.Type] = [FMBenchReportCommand.self]
        #if canImport(FoundationModels)
        commands.insert(FMBenchRunCommand.self, at: 0)
        #endif
        return commands
    }
}

/// Reads JSON Lines records and prints a Markdown table.
struct FMBenchReportCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "report",
        abstract: "Score a JSON Lines results file and print a Markdown table."
    )

    @Argument(help: "The results file written by `fm-bench run`.")
    var file: String

    @Flag(help: "Split each row by the language of the posts.")
    var byLanguage = false

    mutating func run() throws {
        let records = try Self.load(URL(fileURLWithPath: file))
        let rows = BenchReportRow.build(from: records, byLanguage: byLanguage)
        print(BenchReportFormatter.markdown(rows))
    }

    static func load(_ url: URL) throws -> [BenchRecord] {
        let decoder = BenchRecord.makeDecoder()
        let text = try String(contentsOf: url, encoding: .utf8)
        return try text.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            return try decoder.decode(BenchRecord.self, from: Data(trimmed.utf8))
        }
    }
}
