# 🎨 Styling CLI Output with StyledText

Compose colored and formatted text for command-line interfaces using Swift
string interpolation.

## Overview

`StyledText` provides a chainable API — inspired by
[picocolors](https://github.com/alexeyraspopov/picocolors) and
[chalk](https://github.com/chalk/chalk) — to produce ANSI-styled terminal
output. Instead of wrapping an entire line in a single color, you can mix colors
and modifiers freely within a sentence.

```swift
print("\("Hello".red) \("world".blue)")
// prints "Hello" in red, a space, then "world" in blue
```

### Getting Started

Start from any `String` literal and chain style properties. Each property
returns a ``StyledText`` value whose `description` emits the correct ANSI escape
sequences. Because `StyledText` conforms to `CustomStringConvertible`, it works
seamlessly inside string interpolation.

```swift
let label = "Error".red.bold
let message = "file not found".white
print("\(label): \(message)")
```

### Foreground Colors

Set the text color with one of these properties:

```swift
"text".black
"text".red
"text".green
"text".yellow
"text".blue
"text".magenta
"text".cyan
"text".white
```

### Background Colors

Set the background color with the `on`-prefixed properties:

```swift
"WARNING".yellow.onRed
"info".white.onBlue
```

The full list: `.onBlack`, `.onRed`, `.onGreen`, `.onYellow`, `.onBlue`,
`.onMagenta`, `.onCyan`, `.onWhite`.

### Text Modifiers

Apply formatting modifiers, which can be combined with colors:

```swift
"important".bold
"secondary".dim
"title".italic
"link".underline
"deleted".strikethrough
"spoiler".hidden
"swapped".inverse
```

### Chaining Styles

Properties can be chained in any order. Colors and modifiers accumulate:

```swift
"critical".red.bold.onWhite
"note".cyan.italic.underline
```

When the same category is set twice, the last value wins:

```swift
"text".red.blue  // renders in blue
```

Duplicate modifiers are harmless — they are deduplicated automatically.

### Multi-Part Output

Use ``CLIUtils/write(parts:)`` to print multiple styled fragments on a single
line without manually joining them:

```swift
CLIUtils.write(parts: "Status: ".white.bold, "OK".green.bold)
```

### Plain Text Fallback

A ``StyledText`` created without any styling produces the raw string with no
escape codes, so it is safe to use in contexts where ANSI support is uncertain.

```swift
let plain = StyledText("no style")
print(plain) // "no style" — no escape characters
```

## Topics

### Types

- ``StyledText``
- ``ANSIColor``
- ``ANSIModifier``

### CLI Utilities

- ``CLIUtils``
