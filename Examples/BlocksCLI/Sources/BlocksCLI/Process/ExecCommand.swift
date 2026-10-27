import ArgumentParser
import Blocks
import Foundation

/// Runs an executable through `ProcessRunner`, without a shell, and prints its stdout and stderr separately.
struct ExecCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "exec",
        abstract: "Run an executable without a shell and print its stdout and stderr separately.",
        discussion: """
        Arguments after the executable are passed as-is: characters such as &, ?, $, ; or quotes \
        are never interpreted. A bare executable name is resolved against PATH.

        By default, the output is printed once the process has exited. With --stream, it is \
        forwarded to this command's stdout and stderr as it is produced.
        """
    )

    @Option(help: "Text written to the process's standard input.")
    var input: String?

    @Option(help: "Seconds after which the process is terminated.")
    var timeout: TimeInterval?

    @Flag(help: "Forward the output as it is produced instead of printing it at exit.")
    var stream = false

    @Argument(help: "The executable to run, as a path or a name found in PATH.")
    var executable: String

    @Argument(parsing: .captureForPassthrough, help: "The arguments passed to the executable.")
    var arguments: [String] = []

    mutating func run() async throws {
        let runner: any ProcessRunning = ProcessRunner()
        let executableURL = try await resolve(executable, with: runner)

        let inputData = input.map { Data($0.utf8) }
        do {
            if stream {
                for try await event in runner.stream(
                    executableURL, arguments: arguments, input: inputData, timeout: timeout
                ) {
                    switch event {
                    case let .stdout(chunk):
                        FileHandle.standardOutput.write(chunk)
                    case let .stderr(chunk):
                        FileHandle.standardError.write(chunk)
                    }
                }
            } else {
                let output = try await runner.run(
                    executableURL, arguments: arguments, input: inputData, timeout: timeout
                )
                printSection("stdout".green.bold, output.stdout)
                printSection("stderr".yellow.bold, output.stderr)
            }
        } catch let error as ProcessRunnerError {
            print("\("error".red.bold) \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    /// Resolves a bare executable name with `/usr/bin/which`, itself run through `ProcessRunner`.
    private func resolve(_ executable: String, with runner: any ProcessRunning) async throws -> URL {
        guard !executable.contains("/") else {
            return URL(fileURLWithPath: executable)
        }

        do {
            let output = try await runner.run(URL(fileURLWithPath: "/usr/bin/which"), arguments: [executable])
            return URL(fileURLWithPath: output.stdout.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            print("\("error".red.bold) Could not find \(executable) in PATH.")
            throw ExitCode.failure
        }
    }

    private func printSection(_ label: StyledText, _ text: String) {
        guard !text.isEmpty else { return }
        CLIUtils.write(parts: label)
        print(text, terminator: text.hasSuffix("\n") ? "" : "\n")
    }
}
