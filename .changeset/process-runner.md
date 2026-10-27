---
"swift-blocks": minor
---

Add `ProcessRunner` and the `ProcessRunning` protocol to run an executable with
an argument array, without a shell, capturing stdout and stderr separately, with
optional stdin input, timeout, and an `async` variant. `stream` delivers the
output as it is produced, for long-running commands.

The minimum macOS version is raised to 10.15.4.
