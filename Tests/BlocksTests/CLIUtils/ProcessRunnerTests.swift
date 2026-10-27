#if os(macOS) || os(Linux)
import Blocks
import Foundation
import XCTest

final class ProcessRunnerTests: XCTestCase {
    private let runner: any ProcessRunning = ProcessRunner()

    // MARK: - Arguments

    func testArgumentsReachProcessUnchanged() throws {
        let arguments = [
            "https://example.com/watch?v=abc&list=xyz",
            "$HOME",
            "a; rm -rf /",
            "with spaces",
            "\"double\" 'single'"
        ]
        // Calls the concrete type to check that its overloads resolve without the protocol.
        let output = try ProcessRunner().run(
            URL(fileURLWithPath: "/usr/bin/printf"),
            arguments: ["%s\\n"] + arguments
        )
        XCTAssertEqual(output.stdout, arguments.joined(separator: "\n") + "\n")
    }

    // MARK: - Output

    func testStdoutAndStderrAreSeparate() throws {
        let output = try runner.run(
            URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "echo out; echo err >&2"]
        )
        XCTAssertEqual(output, ProcessOutput(stdout: "out\n", stderr: "err\n"))
    }

    // MARK: - Errors

    func testNonZeroExitThrowsWithStatusAndStderr() {
        XCTAssertThrowsError(
            try runner.run(URL(fileURLWithPath: "/bin/sh"), arguments: ["-c", "echo boom >&2; exit 3"])
        ) { error in
            XCTAssertEqual(error as? ProcessRunnerError, .nonZeroExit(status: 3, stderr: "boom\n"))
        }
    }

    func testSignalTerminationIsDistinctFromNonZeroExit() {
        XCTAssertThrowsError(
            try runner.run(URL(fileURLWithPath: "/bin/sh"), arguments: ["-c", "echo dying >&2; kill -9 $$"])
        ) { error in
            XCTAssertEqual(error as? ProcessRunnerError, .terminatedBySignal(signal: 9, stderr: "dying\n"))
        }
    }

    func testDirectoryIsNotAnExecutable() {
        let url = URL(fileURLWithPath: "/tmp")
        XCTAssertThrowsError(try runner.run(url, arguments: [])) { error in
            XCTAssertEqual(error as? ProcessRunnerError, .executableNotFound(url))
        }
    }

    func testMissingExecutableThrowsNamingThePath() {
        let url = URL(fileURLWithPath: "/nonexistent/tool")
        XCTAssertThrowsError(try runner.run(url, arguments: [])) { error in
            XCTAssertEqual(error as? ProcessRunnerError, .executableNotFound(url))
            XCTAssertTrue(error.localizedDescription.contains("/nonexistent/tool"))
        }
    }

    // MARK: - Timeout

    func testTimeoutTerminatesProcessAndThrows() {
        let start = Date()
        XCTAssertThrowsError(
            try runner.run(URL(fileURLWithPath: "/bin/sleep"), arguments: ["10"], timeout: 0.2)
        ) { error in
            XCTAssertEqual(error as? ProcessRunnerError, .timedOut(0.2))
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 5)
    }

    func testTimeoutReturnsWhileGrandchildHoldsPipesOpen() {
        let start = Date()
        XCTAssertThrowsError(
            try runner.run(URL(fileURLWithPath: "/bin/sh"), arguments: ["-c", "sleep 10 & sleep 10"], timeout: 0.2)
        ) { error in
            XCTAssertEqual(error as? ProcessRunnerError, .timedOut(0.2))
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 5)
    }

    func testTimeoutKillsProcessIgnoringSIGTERM() {
        let start = Date()
        XCTAssertThrowsError(
            try runner.run(
                URL(fileURLWithPath: "/bin/sh"),
                arguments: ["-c", "trap '' TERM; while :; do sleep 0.1; done"],
                timeout: 0.2
            )
        ) { error in
            XCTAssertEqual(error as? ProcessRunnerError, .timedOut(0.2))
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 5)
    }

    func testProcessFinishingWithinTimeoutSucceeds() throws {
        let output = try runner.run(URL(fileURLWithPath: "/bin/echo"), arguments: ["fast"], timeout: 10)
        XCTAssertEqual(output.stdout, "fast\n")
    }

    // MARK: - Input

    func testInputIsWrittenToStdin() throws {
        let output = try runner.run(
            URL(fileURLWithPath: "/bin/cat"),
            arguments: [],
            input: Data("<html>héllo</html>".utf8)
        )
        XCTAssertEqual(output.stdout, "<html>héllo</html>")
    }

    func testInputIgnoredByProcessDoesNotCrash() throws {
        let output = try runner.run(
            URL(fileURLWithPath: "/usr/bin/true"),
            arguments: [],
            input: Data(count: 1_000_000)
        )
        XCTAssertEqual(output.stdout, "")
    }

    func testStdinIsClosedWithoutInput() throws {
        let output = try runner.run(URL(fileURLWithPath: "/bin/cat"), arguments: [])
        XCTAssertEqual(output.stdout, "")
    }

    func testLargeOutputOnBothStreamsDoesNotDeadlock() throws {
        // Exceeds the 64 KiB pipe buffer on both streams at once.
        let output = try runner.run(
            URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "head -c 200000 /dev/zero | tr '\\0' o; head -c 200000 /dev/zero | tr '\\0' e >&2"]
        )
        XCTAssertEqual(output.stdout.count, 200_000)
        XCTAssertEqual(output.stderr.count, 200_000)
    }

    // MARK: - Async

    func testAsyncRunReturnsOutput() async throws {
        let output = try await runner.run(
            URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "cat; echo err >&2"],
            input: Data("in".utf8)
        )
        XCTAssertEqual(output, ProcessOutput(stdout: "in", stderr: "err\n"))
    }

    func testAsyncRunThrowsOnTimeout() async {
        do {
            _ = try await runner.run(URL(fileURLWithPath: "/bin/sleep"), arguments: ["10"], timeout: 0.2)
            XCTFail("Expected a timeout")
        } catch {
            XCTAssertEqual(error as? ProcessRunnerError, .timedOut(0.2))
        }
    }

    // MARK: - Streaming

    func testStreamYieldsStdoutAndStderr() async throws {
        var stdout = Data()
        var stderr = Data()
        for try await event in runner.stream(
            URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "cat; echo err >&2"],
            input: Data("in".utf8)
        ) {
            switch event {
            case let .stdout(chunk): stdout.append(chunk)
            case let .stderr(chunk): stderr.append(chunk)
            }
        }
        XCTAssertEqual(stdout, Data("in".utf8))
        XCTAssertEqual(stderr, Data("err\n".utf8))
    }

    func testStreamDeliversOutputBeforeProcessExits() async throws {
        let start = Date()
        let events = runner.stream(URL(fileURLWithPath: "/bin/sh"), arguments: ["-c", "echo first; sleep 10"])
        var iterator = events.makeAsyncIterator()
        let first = try await iterator.next()
        XCTAssertEqual(first, .stdout(Data("first\n".utf8)))
        XCTAssertLessThan(Date().timeIntervalSince(start), 5)
    }

    func testCancellingStreamTerminatesProcess() async throws {
        let (pids, pidContinuation) = AsyncStream<pid_t>.makeStream()
        let consumer = Task { [runner] in
            let events = runner.stream(URL(fileURLWithPath: "/bin/sh"), arguments: ["-c", "echo $$; exec sleep 30"])
            for try await event in events {
                guard case let .stdout(chunk) = event, let text = String(bytes: chunk, encoding: .utf8) else {
                    continue
                }
                pid_t(text.trimmingCharacters(in: .whitespacesAndNewlines)).map { pidContinuation.yield($0) }
            }
        }
        var pidIterator = pids.makeAsyncIterator()
        let firstPID = await pidIterator.next()
        let pid = try XCTUnwrap(firstPID)

        consumer.cancel()

        let deadline = Date().addingTimeInterval(3)
        while kill(pid, 0) == 0, Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertNotEqual(kill(pid, 0), 0, "Process \(pid) is still running")
    }

    func testStreamThrowsOnNonZeroExit() async {
        var stderr = Data()
        do {
            for try await event in runner.stream(
                URL(fileURLWithPath: "/bin/sh"),
                arguments: ["-c", "echo boom >&2; exit 3"]
            ) {
                if case let .stderr(chunk) = event {
                    stderr.append(chunk)
                }
            }
            XCTFail("Expected a non-zero exit")
        } catch {
            XCTAssertEqual(error as? ProcessRunnerError, .nonZeroExit(status: 3, stderr: "boom\n"))
        }
        XCTAssertEqual(stderr, Data("boom\n".utf8))
    }

    func testFakeImplementingOnlyRunCanBeStreamed() async throws {
        let fake: any ProcessRunning = FakeProcessRunner(output: ProcessOutput(stdout: "out", stderr: "err"))
        var events: [ProcessEvent] = []
        for try await event in fake.stream(URL(fileURLWithPath: "/fake"), arguments: []) {
            events.append(event)
        }
        XCTAssertEqual(events, [.stdout(Data("out".utf8)), .stderr(Data("err".utf8))])
    }
}

private struct FakeProcessRunner: ProcessRunning {
    let output: ProcessOutput

    func run(_: URL, arguments _: [String], input _: Data?, timeout _: TimeInterval?) throws -> ProcessOutput {
        output
    }
}
#endif
