# Running Interactive Shell Commands

Run external commands that need full terminal access — preserving colors,
formatting, and user input.

## Overview

`CLIUtils` provides two ways to run shell commands:

| Method | stdin | stdout | stderr | Returns |
|---|---|---|---|---|
| ``CLIUtils/shell(_:)`` | closed | captured | captured | `String` |
| ``CLIUtils/interactiveShell(_:captureOutput:)`` | TTY | TTY or captured | TTY | `String?` |

Use ``CLIUtils/shell(_:)`` when you need to silently run a command and read its
output. Use ``CLIUtils/interactiveShell(_:captureOutput:)`` when the command
renders a TUI, prompts the user, or produces colored output that should appear
in the terminal.

## Run a Command with Full TTY Passthrough

When `captureOutput` is `false` (the default), the child process inherits
stdin, stdout, and stderr from the parent. Everything the command prints appears
directly in the terminal and the user can interact with it normally.

```swift
// Show a spinner while a long task runs.
try CLIUtils.interactiveShell("gum spin --title 'Building…' -- make build")
```

## Capture the Result of an Interactive Command

Many TUI tools — such as [gum](https://github.com/charmbracelet/gum),
[fzf](https://github.com/junegunn/fzf), and
[inquirer](https://github.com/SBoudrias/Inquirer.js) — render their interface
on **stderr** and write the user's selection to **stdout**. Setting
`captureOutput` to `true` pipes stdout back to your code while keeping stdin
and stderr connected to the terminal.

```swift
let commitType = try CLIUtils.interactiveShell(
    "gum choose fix feat docs style refactor test chore revert",
    captureOutput: true
)
print("Selected: \(commitType ?? "nothing")")
```

The returned string is trimmed of leading and trailing whitespace. If the
command produces no stdout output, the result is an empty string.

## Choose the Right Method

Use this decision tree to pick the right shell API:

1. **Does the command need to display a TUI or prompt the user?**
   → Use ``CLIUtils/interactiveShell(_:captureOutput:)``
2. **Do you also need to read the command's stdout result?**
   → Pass `captureOutput: true`
3. **Is the command non-interactive and you just need its output?**
   → Use ``CLIUtils/shell(_:)``

## Topics

### CLI Utilities

- ``CLIUtils``
