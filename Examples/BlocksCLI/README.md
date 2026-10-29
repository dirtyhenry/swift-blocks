# Blocks CLI

`blocks-cli` is a demo command-line tool for the [Blocks](../../README.md)
library. Each subcommand exercises one part of the library in a real program,
and doubles as a handy developer tool.

It depends on the local `Blocks` package and on
[swift-argument-parser](https://github.com/apple/swift-argument-parser).

## Requirements

- macOS 10.15.4 or later (`curl` needs macOS 12, `ai-demo` macOS 26)
- A Swift 6 toolchain (Xcode 16 or later)

## Build and Run

From the repository root:

```sh
make cli
```

Or from this directory:

```sh
swift build
swift run blocks-cli --help
```

The binary is written to `.build/debug/blocks-cli`. Every subcommand accepts
`--help`:

```sh
swift run blocks-cli exec --help
```

## Commands

| Command              | What it does                                                                   | Blocks API shown                                            |
| -------------------- | ------------------------------------------------------------------------------ | ----------------------------------------------------------- |
| `exec`               | Runs an executable without a shell and prints its stdout and stderr separately | `ProcessRunner`, `ProcessRunning.stream`                    |
| `curl`               | Fetches a URL, curl-style                                                      | `Transport`                                                 |
| `print-colors`       | Shows the styles available for terminal output                                 | `StyledText`, `CLIUtils.write`, `CLIUtils.interactiveShell` |
| `password`           | Reads a password without echoing it                                            | `CLIUtils.readLine(prompt:secure:)`                         |
| `lint-copy`          | Replaces straight apostrophes with typographic ones                            | `CopyUtils.lint(input:)`                                    |
| `slugify`            | Turns text into a URL slug                                                     | `String.slugify()`                                          |
| `filename`           | Turns a title into a safe filename that is easy to read                        | `String.sanitizedFilename()`                                |
| `list-simulators`    | Lists or filters the available Xcode simulators                                | `CLIUtils.shell(_:)`                                        |
| `gen-tests`          | Prints a `swift test` command for every test target in a package dump          | `PackageDump`                                               |
| `new-note`           | Prints a new Markdown note with front matter                                   | `FrontMatterEncoder`                                        |
| `list-ips`           | Lists the private IPv4 addresses of this machine                               | —                                                           |
| `merge-translations` | Merges two JSON translation files                                              | —                                                           |
| `gen-barcode`        | Creates a QR or Aztec barcode image                                            | — (Core Image)                                              |
| `read-barcode`       | Reads the payload of a barcode image                                           | — (Vision)                                                  |
| `ai-demo`            | Rewrites product copy with the on-device model                                 | — (Foundation Models, macOS 26)                             |

### `exec`

Runs an executable with `ProcessRunner`. Arguments after the executable reach it
unchanged: nothing is interpreted by a shell, so URLs with `&` or `?` and values
such as `$HOME` are passed through as they are. A bare executable name is
resolved against `PATH`.

```sh
blocks-cli exec printf '%s\n' 'https://example.com/watch?v=a&list=b' '$HOME'
```

```text
stdout
https://example.com/watch?v=a&list=b
$HOME
```

Write to the process's standard input with `--input`; stdout and stderr are
printed separately:

```sh
blocks-cli exec --input 'hello' sh -c 'cat; echo oops >&2'
```

```text
stdout
hello
stderr
oops
```

By default, the output is printed once the process has exited. Pass `--stream`
to forward it as it is produced, which shows the progress of long-running
commands:

```sh
blocks-cli exec --stream sh -c 'for i in 1 2 3; do echo "tick $i"; sleep 1; done'
```

Stop a process that runs too long with `--timeout` (in seconds). The command
exits with status 1 on a timeout, a non-zero exit, a signal, or a missing
executable:

```sh
blocks-cli exec --timeout 0.5 sleep 5
# error Command did not finish within 0.5 seconds.
```

### `curl`

```sh
blocks-cli curl https://example.com --headers 'Accept: text/html'
```

### `print-colors`

```sh
blocks-cli print-colors
```

### `password`

```sh
blocks-cli password
```

### `lint-copy`

```sh
blocks-cli lint-copy "It's the user's call"
# It’s the user’s call
```

### `filename`

This command makes a safe filename from a title. The filename keeps accents,
emoji and spaces. The result is easy to read.

```sh
blocks-cli filename 'Swift: Codable / JSON #1' --extension md
# Swift Codable JSON 1.md
```

To compare the filename with the slug of the same title, use `--compare`:

```sh
blocks-cli filename --compare 'Café ☕️ notes'
# filename: Café ☕️ notes
# slug:     cafe-notes
```

Use these options to change the result:

- `--extension`: An extension to add to the filename, such as `md`.
- `--max-length`: The maximum length of the filename, in UTF-8 bytes. The
  default is 200.

Use `filename` for files that people read. Use `slugify` for URLs.

### `slugify`

```sh
blocks-cli slugify 'Hello, World!'
# hello-world
```

### `list-simulators`

Without filters, lists every available simulator. With both filters, prints the
UDID of the single matching simulator:

```sh
blocks-cli list-simulators
blocks-cli list-simulators --os-filter 'iOS 18.0' --device-filter 'iPhone 16'
```

### `gen-tests`

```sh
swift package dump-package > package.json
blocks-cli gen-tests package.json
```

### `list-ips`

```sh
blocks-cli list-ips
blocks-cli list-ips --json
```

### `new-note`

This command prints a new Markdown note. The note starts with a front matter
block. `FrontMatterEncoder` writes this block.

To make a note, give its title:

```sh
blocks-cli new-note 'Swift: "Codable" tips #1' --tag swift --tag 'yaml: fun'
```

The command prints this text:

```text
---
title: "Swift: \"Codable\" tips #1"
date: 2026-10-27
tags: ["swift", "yaml: fun"]
draft: false
---

# Swift: "Codable" tips #1
```

The title and the tags can contain quotation marks, colons, `#` and emoji.

Use these options to change the front matter:

- `--date`: The date of the note, as `YYYY-MM-DD`. The default is today.
- `--tag`: A tag. Use this option one time for each tag.
- `--source`: The URL of the source of the note.
- `--draft`: Mark the note as a draft.

To keep the note, send the output to a file:

```sh
blocks-cli new-note 'My note' > my-note.md
```

### `merge-translations`

Merges two flat JSON dictionaries; keys from the second file win:

```sh
blocks-cli merge-translations en.json en-overrides.json merged.json
```

### `gen-barcode` and `read-barcode`

```sh
blocks-cli gen-barcode 'https://example.com' --symbology aztec --output-filename code.png
blocks-cli read-barcode code.png --json
```

### `ai-demo`

Requires macOS 26 and an Apple Intelligence-eligible device. The command is only
built when the SDK provides `FoundationModels`.

```sh
blocks-cli ai-demo 'our app is very fast and good'
```

## Tests

```sh
swift test
```

## Distribution

`blocks-cli` is **not notarized** and is not distributed as a signed binary.
Build it from source with `make cli` from the repository root.

### Why not Xcode Cloud?

Notarizing this tool with Xcode Cloud was investigated and abandoned. Xcode
Cloud's Notarize post-action fails here with:

> No developer ID export was generated from the archive stage. This usually
> happens if your WWDR team does not have developer ID export capability
> enabled.

The message points at an account capability, but that is a red herring. Two
independent blockers apply, and either one alone is fatal:

1. **Xcode Cloud cannot build standalone Swift packages.** `BlocksCLI` is
   exactly that, with no wrapping `.xcodeproj`. See [Building Swift packages
   with Xcode Cloud][spm-xcc].
2. **A command-line tool cannot produce a Developer ID export.** The Notarize
   post-action runs `xcodebuild -exportArchive` with `method = developer-id`. A
   command-line tool target archives to `Products/usr/local/bin/…` rather than a
   single top-level `.app`, which makes it a _generic_ archive that cannot be
   validated or distributed — see [TN3110][tn3110]. The export fails with
   `expected one of {}, but found developer-id`, so
   `CI_DEVELOPER_ID_SIGNED_APP_PATH` is never populated.

Xcode Cloud's notarization support is scoped to macOS **app** archives. Apple's
own guidance for command-line tools is to skip `-exportArchive` and script
notarization manually — see [Customizing the notarization
workflow][custom-notary].

Working around this inside Xcode Cloud is also a dead end: its build keychain
holds no Developer ID identity, and it deletes any file a custom
`ci_post_xcodebuild.sh` creates.

### If notarization is ever needed

Do it outside Xcode Cloud, from a Makefile target or a GitHub Actions release
workflow: `swift build -c release` → `codesign --options runtime --timestamp` →
package → `xcrun notarytool submit --wait` → `xcrun stapler staple`. Note that a
bare Mach-O executable cannot be stapled, so the ticket has to be stapled to a
container (`.pkg` or `.dmg`); a zipped binary notarizes fine but relies on an
online Gatekeeper check at first launch.

[spm-xcc]:
  https://developer.apple.com/documentation/xcode/building-swift-packages-or-swift-playground-app-projects-with-xcode-cloud
[tn3110]:
  https://developer.apple.com/documentation/technotes/tn3110-resolving-generic-xcode-archive-issue
[custom-notary]:
  https://developer.apple.com/documentation/security/customizing-the-notarization-workflow
