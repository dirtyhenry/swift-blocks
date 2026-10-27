# Running External Processes

Run an executable with an argument array, without a shell, and read its
standard output and standard error separately.

## Overview

``ProcessRunner`` is meant for command-line tools that receive untrusted
arguments, such as URLs, and whose stdout is data to be parsed.
Unlike ``CLIUtils/shell(_:)``, no shell is involved: each argument reaches the
process unchanged, even when it contains `&`, `?`, `$`, `;`, spaces or quotes.

```swift
let runner = ProcessRunner()
let output = try runner.run(
    URL(fileURLWithPath: "/usr/bin/sort"),
    arguments: ["--unique"],
    input: Data("pear\napple\npear\n".utf8),
    timeout: 30
)
print(output.stdout) // "apple\npear\n"
```

The executable is given by URL; no `PATH` lookup is performed. When `input` is
`nil`, the process reads an empty standard input.

## Handle Failures

All errors are ``ProcessRunnerError`` values:

- ``ProcessRunnerError/executableNotFound(_:)`` when no executable file exists
  at the given URL.
- ``ProcessRunnerError/nonZeroExit(status:stderr:)`` when the process fails; the
  error carries its exit status and standard error.
- ``ProcessRunnerError/terminatedBySignal(signal:stderr:)`` when the process is
  killed by a signal it did not handle.
- ``ProcessRunnerError/timedOut(_:)`` when the process outlives `timeout`. It
  receives `SIGTERM`, then `SIGKILL` one second later if it is still running.
  The call returns without waiting for processes it spawned.

## Stream Output as It Is Produced

``ProcessRunner/run(_:arguments:input:timeout:)`` returns once the process has
exited, so a long-running command shows no progress until the end. Use
``ProcessRunning/stream(_:arguments:input:timeout:)`` to receive its output as it
is produced instead. It takes the same arguments and returns an
`AsyncThrowingStream` of ``ProcessEvent`` values:

```swift
let git = URL(fileURLWithPath: "/usr/bin/git")
for try await event in runner.stream(git, arguments: ["clone", "--progress", repositoryURL]) {
    switch event {
    case let .stdout(chunk):
        FileHandle.standardOutput.write(chunk)
    case let .stderr(chunk):
        FileHandle.standardError.write(chunk)
    }
}
```

The stream finishes when the process exits successfully and throws a
``ProcessRunnerError`` otherwise, as `run` does. Cancelling the task that
iterates the stream terminates the process.

Chunks are raw bytes, delivered as soon as the process writes them. A chunk may
end in the middle of a line or of a UTF-8 character, so buffer chunks before
splitting them into lines. Chunks of each stream arrive in order, but the order
between stdout and stderr chunks is not guaranteed.

## Use from Async Code

Every `run` overload has an `async` counterpart that waits for the process on a
background queue instead of blocking the caller. Cancelling the calling task
does not terminate the process; use a timeout to bound it.

```swift
let curl = URL(fileURLWithPath: "/usr/bin/curl")
let output = try await runner.run(curl, arguments: ["--silent", "--fail", untrustedURL])
```

## Inject a Fake in Tests

Depend on the ``ProcessRunning`` protocol rather than on ``ProcessRunner`` so
that tests can provide canned output. A conforming type only needs to implement
the synchronous `run(_:arguments:input:timeout:)` requirement: the `async` and
streaming variants call it, and the stream delivers its whole output in one
stdout chunk followed by one stderr chunk.

```swift
struct FakeProcessRunner: ProcessRunning {
    let output: ProcessOutput

    func run(
        _ executableURL: URL,
        arguments: [String],
        input: Data?,
        timeout: TimeInterval?
    ) throws -> ProcessOutput {
        output
    }
}
```

## Choose the Right API

Blocks offers four ways to run an external command. They differ in whether a
shell is involved, where the output goes, and when you get it.

| API | Shell | stdin | stdout | stderr | You get the output | Platforms |
|---|---|---|---|---|---|---|
| ``CLIUtils/shell(_:)`` | yes | closed | captured | merged into stdout | at exit, as one `String` | macOS |
| ``CLIUtils/interactiveShell(_:captureOutput:)`` | yes | terminal | terminal, or captured | terminal | live on the terminal; captured stdout at exit | macOS |
| ``ProcessRunner/run(_:arguments:input:timeout:)`` | no | empty or `Data` | captured | captured, separately | at exit, as ``ProcessOutput`` | macOS, Linux |
| ``ProcessRunning/stream(_:arguments:input:timeout:)`` | no | empty or `Data` | streamed | streamed, separately | live, as ``ProcessEvent`` chunks | macOS, Linux |

Pick the API from what the command needs:

- **A fixed command line written by you, where you just want the text**: for
  example `git rev-parse HEAD`. Use ``CLIUtils/shell(_:)``. Shell syntax such as
  pipes and globs works.
- **A command that draws a user interface or asks the user for input**: for
  example `fzf`, `gum`, or `git commit` opening an editor. Use
  ``CLIUtils/interactiveShell(_:captureOutput:)``. Pass `captureOutput: true` to
  read the user's selection from stdout.
- **Arguments you did not write, such as URLs, filenames or user input**: use
  ``ProcessRunner``. No shell interprets them, so `&`, `$`, `;` or quotes cannot
  change the command. It also separates stdout from stderr, writes `input` to
  stdin, and enforces a timeout.
- **Output you parse once the command is done**: for example JSON from
  `curl --silent`. Use ``ProcessRunner/run(_:arguments:input:timeout:)``.
- **A long-running command whose progress you want to show, or output too large
  to hold in memory**: for example `git clone --progress` or `tail -f`. Use
  ``ProcessRunning/stream(_:arguments:input:timeout:)``.
- **Code you want to test without running real commands**: depend on
  ``ProcessRunning`` and inject a fake. The `CLIUtils` functions cannot be
  replaced in tests.

## Topics

### Running Processes

- ``ProcessRunning``
- ``ProcessRunner``
- ``ProcessOutput``
- ``ProcessEvent``
- ``ProcessRunnerError``
