#if os(macOS) || os(Linux)
import Foundation

/// The captured output of a process that exited successfully.
public struct ProcessOutput: Equatable, Sendable {
    /// Everything the process wrote to standard output, decoded as UTF-8.
    public let stdout: String
    /// Everything the process wrote to standard error, decoded as UTF-8.
    public let stderr: String

    public init(stdout: String, stderr: String) {
        self.stdout = stdout
        self.stderr = stderr
    }
}

/// A chunk of output produced by a running process, as delivered by ``ProcessRunning/stream(_:arguments:input:timeout:)``.
///
/// Chunks are raw bytes as read from the pipe: a chunk may end in the middle of a line or of a UTF-8 character.
public enum ProcessEvent: Equatable, Sendable {
    /// Bytes the process wrote to standard output.
    case stdout(Data)
    /// Bytes the process wrote to standard error.
    case stderr(Data)
}

/// The errors thrown by a ``ProcessRunning`` implementation.
public enum ProcessRunnerError: Error, Equatable, Sendable {
    /// No executable file (other than a directory) exists at the given URL.
    case executableNotFound(URL)
    /// The process exited with a non-zero status. `stderr` holds what it wrote to standard error.
    case nonZeroExit(status: Int32, stderr: String)
    /// The process was killed by an uncaught signal. `stderr` holds what it wrote to standard error.
    case terminatedBySignal(signal: Int32, stderr: String)
    /// The process did not finish within the given number of seconds and was terminated.
    case timedOut(TimeInterval)
}

extension ProcessRunnerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .executableNotFound(url):
            "No executable file found at \(url.path)."
        case let .nonZeroExit(status, stderr):
            "Command failed with status \(status): \(stderr)"
        case let .terminatedBySignal(signal, stderr):
            "Command terminated by signal \(signal): \(stderr)"
        case let .timedOut(timeout):
            "Command did not finish within \(timeout) seconds."
        }
    }
}

/// Runs an external executable with an argument array and captures its output.
///
/// Conform a fake to this protocol to stub external commands in tests.
public protocol ProcessRunning: Sendable {
    /// Runs an executable and waits for it to exit.
    ///
    /// - Parameters:
    ///   - executableURL: The file URL of the executable. No `PATH` lookup is performed.
    ///   - arguments: The arguments passed to the executable as-is, without any shell interpretation.
    ///   - input: Data written to the process's standard input. When `nil`, standard input is empty.
    ///   - timeout: The number of seconds after which the process is terminated. When `nil`, there is no limit.
    /// - Returns: The process's standard output and standard error.
    /// - Throws: A ``ProcessRunnerError``.
    func run(
        _ executableURL: URL,
        arguments: [String],
        input: Data?,
        timeout: TimeInterval?
    ) throws -> ProcessOutput

    /// Runs an executable without blocking the current thread.
    ///
    /// The parameters, result and errors are the same as for the synchronous variant.
    func run(
        _ executableURL: URL,
        arguments: [String],
        input: Data?,
        timeout: TimeInterval?
    ) async throws -> ProcessOutput

    /// Runs an executable and delivers its output as it is produced.
    ///
    /// The stream finishes when the process exits successfully, and throws a ``ProcessRunnerError`` otherwise.
    /// Cancelling the task that iterates the stream, or releasing the stream, terminates the process. Chunks from standard output and standard
    /// error are each delivered in order, but their relative order is not guaranteed.
    ///
    /// The parameters are the same as for `run`.
    func stream(
        _ executableURL: URL,
        arguments: [String],
        input: Data?,
        timeout: TimeInterval?
    ) -> AsyncThrowingStream<ProcessEvent, Error>
}

public extension ProcessRunning {
    /// Runs the synchronous variant on a background queue.
    func run(
        _ executableURL: URL,
        arguments: [String],
        input: Data?,
        timeout: TimeInterval?
    ) async throws -> ProcessOutput {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(with: Result {
                    try run(executableURL, arguments: arguments, input: input, timeout: timeout) as ProcessOutput
                })
            }
        }
    }

    /// Runs an executable without a timeout.
    func run(_ executableURL: URL, arguments: [String], input: Data? = nil) throws -> ProcessOutput {
        try run(executableURL, arguments: arguments, input: input, timeout: nil)
    }

    /// Runs an executable, terminating it after `timeout` seconds.
    func run(
        _ executableURL: URL,
        arguments: [String],
        input: Data? = nil,
        timeout: TimeInterval
    ) throws -> ProcessOutput {
        try run(executableURL, arguments: arguments, input: input, timeout: Optional(timeout))
    }

    /// Runs an executable without a timeout and without blocking the current thread.
    func run(_ executableURL: URL, arguments: [String], input: Data? = nil) async throws -> ProcessOutput {
        try await run(executableURL, arguments: arguments, input: input, timeout: nil)
    }

    /// Runs an executable, terminating it after `timeout` seconds, without blocking the current thread.
    func run(
        _ executableURL: URL,
        arguments: [String],
        input: Data? = nil,
        timeout: TimeInterval
    ) async throws -> ProcessOutput {
        try await run(executableURL, arguments: arguments, input: input, timeout: Optional(timeout))
    }

    /// Runs the asynchronous `run` and delivers its whole output at the end, as one standard output chunk followed by
    /// one standard error chunk.
    ///
    /// This lets fakes that only implement `run` be used where a stream is expected.
    func stream(
        _ executableURL: URL,
        arguments: [String],
        input: Data?,
        timeout: TimeInterval?
    ) -> AsyncThrowingStream<ProcessEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let output: ProcessOutput = try await run(
                        executableURL, arguments: arguments, input: input, timeout: timeout
                    )
                    if !output.stdout.isEmpty {
                        continuation.yield(.stdout(Data(output.stdout.utf8)))
                    }
                    if !output.stderr.isEmpty {
                        continuation.yield(.stderr(Data(output.stderr.utf8)))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Streams the output of an executable without a timeout.
    func stream(
        _ executableURL: URL,
        arguments: [String],
        input: Data? = nil
    ) -> AsyncThrowingStream<ProcessEvent, Error> {
        stream(executableURL, arguments: arguments, input: input, timeout: nil)
    }

    /// Streams the output of an executable, terminating it after `timeout` seconds.
    func stream(
        _ executableURL: URL,
        arguments: [String],
        input: Data? = nil,
        timeout: TimeInterval
    ) -> AsyncThrowingStream<ProcessEvent, Error> {
        stream(executableURL, arguments: arguments, input: input, timeout: Optional(timeout))
    }
}

/// Runs external executables with `Foundation.Process`, without involving a shell.
///
/// Unlike ``CLIUtils/shell(_:)``, arguments are never interpreted, so untrusted values such as URLs can be passed
/// safely, and standard output is kept apart from standard error so it can be parsed as data.
///
/// ```swift
/// let runner: any ProcessRunning = ProcessRunner()
/// let output = try await runner.run(
///     URL(fileURLWithPath: "/usr/bin/curl"),
///     arguments: ["--silent", "--fail", untrustedURL],
///     timeout: 60
/// )
/// ```
///
/// On timeout, the process receives `SIGTERM`, then `SIGKILL` one second later if it is still running. Processes it
/// spawned are not signalled.
///
/// - Note: On Linux, passing `input` sets `SIGPIPE` to be ignored for the whole program, so that a process exiting
///   before reading all its input does not kill the caller.
public struct ProcessRunner: ProcessRunning {
    public init() {}

    public func run(
        _ executableURL: URL,
        arguments: [String],
        input: Data?,
        timeout: TimeInterval?
    ) throws -> ProcessOutput {
        let stdout = OutputBuffer()
        let stderr = try execute(
            executableURL,
            arguments: arguments,
            input: input,
            timeout: timeout,
            onStdout: { stdout.append($0) }
        )
        return ProcessOutput(stdout: lossyUTF8String(stdout.value), stderr: lossyUTF8String(stderr))
    }

    public func stream(
        _ executableURL: URL,
        arguments: [String],
        input: Data?,
        timeout: TimeInterval?
    ) -> AsyncThrowingStream<ProcessEvent, Error> {
        AsyncThrowingStream { continuation in
            let cancellation = ProcessCancellation()
            continuation.onTermination = { termination in
                if case .cancelled = termination {
                    cancellation.cancel()
                }
            }
            DispatchQueue.global().async {
                do {
                    _ = try execute(
                        executableURL,
                        arguments: arguments,
                        input: input,
                        timeout: timeout,
                        onStart: { cancellation.attach($0) },
                        onStdout: { continuation.yield(.stdout($0)) },
                        onStderr: { continuation.yield(.stderr($0)) }
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Runs an executable, hands its output chunks to the given closures as they are read, and waits for it to exit.
    ///
    /// The closures are called from background threads.
    ///
    /// - Returns: Everything the process wrote to standard error, which successful callers may also want.
    private func execute(
        _ executableURL: URL,
        arguments: [String],
        input: Data?,
        timeout: TimeInterval?,
        onStart: (Process) -> Void = { _ in },
        onStdout: @escaping @Sendable (Data) -> Void,
        onStderr: @escaping @Sendable (Data) -> Void = { _ in }
    ) throws -> Data {
        try validateExecutable(at: executableURL)

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let stdinPipe = input.map { _ in Pipe() }
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardInput = stdinPipe ?? FileHandle.nullDevice
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        let exited = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in exited.signal() }
        try process.run()
        onStart(process)

        // Feed stdin and drain both outputs concurrently so that no pipe fills up and blocks either side.
        let stderrData = OutputBuffer()
        let group = DispatchGroup()
        if let input, let stdinPipe {
            let handle = stdinPipe.fileHandleForWriting
            disableSIGPIPE(on: handle)
            DispatchQueue.global().async(group: group) {
                // The child may exit without reading everything; ignore the resulting EPIPE.
                try? handle.write(contentsOf: input)
                try? handle.close()
            }
        }
        DispatchQueue.global().async(group: group) {
            drain(stdoutPipe.fileHandleForReading, into: onStdout)
        }
        DispatchQueue.global().async(group: group) {
            drain(stderrPipe.fileHandleForReading) { chunk in
                stderrData.append(chunk)
                onStderr(chunk)
            }
        }

        let timeoutFired = timeout.map { terminate(process, after: $0, onTimeout: { exited.signal() }) }

        exited.wait()

        if let timeout, timeoutFired?.isSet == true {
            // Don't wait for the exit to be reported or for the pipes to close: processes spawned by the child may
            // hold them open, and on Linux, `Process` only reports the exit once they have all exited.
            throw ProcessRunnerError.timedOut(timeout)
        }

        process.waitUntilExit()
        group.wait()
        let stderr = lossyUTF8String(stderrData.value)
        switch process.terminationReason {
        case .uncaughtSignal:
            throw ProcessRunnerError.terminatedBySignal(signal: process.terminationStatus, stderr: stderr)
        case .exit where process.terminationStatus != 0:
            throw ProcessRunnerError.nonZeroExit(status: process.terminationStatus, stderr: stderr)
        default:
            return stderrData.value
        }
    }
}

/// Reads `handle` until end of file, passing each chunk to `handler` as soon as it is available.
private func drain(_ handle: FileHandle, into handler: (Data) -> Void) {
    while true {
        let chunk = handle.availableData
        guard !chunk.isEmpty else { return }
        handler(chunk)
    }
}

/// Throws ``ProcessRunnerError/executableNotFound(_:)`` unless `url` points to an executable file.
private func validateExecutable(at url: URL) throws {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
          !isDirectory.boolValue,
          FileManager.default.isExecutableFile(atPath: url.path)
    else {
        throw ProcessRunnerError.executableNotFound(url)
    }
}

/// Sends `SIGTERM` to `process` after `timeout` seconds, then `SIGKILL` if it ignores it.
///
/// - Parameter onTimeout: Called after the flag is set, when the timeout fires while the process is still running.
/// - Returns: A flag that is set when the timeout fired while the process was still running.
private func terminate(
    _ process: Process,
    after timeout: TimeInterval,
    onTimeout: @escaping @Sendable () -> Void
) -> OneWayFlag {
    let fired = OneWayFlag()
    DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
        guard process.isRunning else { return }
        fired.set()
        terminateEscalating(process)
        onTimeout()
    }
    return fired
}

/// Sends `SIGTERM` to `process`, then `SIGKILL` one second later if it is still running.
private func terminateEscalating(_ process: Process) {
    process.terminate()
    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
        if process.isRunning {
            kill(process.processIdentifier, SIGKILL)
        }
    }
}

/// Terminates a streamed process when its consumer goes away, even if that happens before the process has started.
private final class ProcessCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var isCancelled = false

    func attach(_ process: Process) {
        let shouldTerminate = lock.withLock {
            self.process = process
            return isCancelled
        }
        if shouldTerminate {
            terminateEscalating(process)
        }
    }

    func cancel() {
        let process = lock.withLock {
            isCancelled = true
            return self.process
        }
        if let process, process.isRunning {
            terminateEscalating(process)
        }
    }
}

/// Decodes output as UTF-8, replacing invalid bytes rather than discarding the whole output.
private func lossyUTF8String(_ data: Data) -> String {
    // swiftlint:disable:next optional_data_string_conversion
    String(decoding: data, as: UTF8.self)
}

/// Prevents a write to a pipe whose reader has exited from killing the current process.
private func disableSIGPIPE(on handle: FileHandle) {
    #if os(Linux)
    // Linux has no per-descriptor equivalent of `F_SETNOSIGPIPE`.
    signal(SIGPIPE, SIG_IGN)
    #else
    _ = fcntl(handle.fileDescriptor, F_SETNOSIGPIPE, 1)
    #endif
}

/// A thread-safe boolean that can only go from `false` to `true`.
private final class OneWayFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    var isSet: Bool {
        lock.withLock { value }
    }

    func set() {
        lock.withLock { value = true }
    }
}

/// Holds data written by a single background reader; access is ordered by a `DispatchGroup`.
private final class OutputBuffer: @unchecked Sendable {
    private(set) var value = Data()

    func append(_ chunk: Data) {
        value.append(chunk)
    }
}
#endif
