import ArgumentParser
import Blocks
import Foundation

@available(macOS 10.15.0, *)
struct GenerateTestCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gen-tests",
        abstract: "A command to generate tests instructions for all test targets of a package."
    )

    @Argument(help: "URL of the package dump file.")
    var inputPath: String

    mutating func run() async throws {
        let data = try Data(contentsOfFileWithPath: inputPath)
        let packageDump = try JSONDecoder().decode(PackageDump.self, from: data)

        packageDump.targets
            .filter { $0.type == "test" }
            .forEach { testTarget in
                print("swift test --target \(testTarget.name)")
            }
    }
}
