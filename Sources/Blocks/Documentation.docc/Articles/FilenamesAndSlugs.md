# Filenames and Slugs

Make a filename or a URL slug from a title.

## Overview

Blocks has two methods that change a title into a safe identifier:

- ``Swift/StringProtocol/sanitizedFilename(maxLength:fallback:)`` makes a
  filename. The filename is easy to read.
- ``Swift/StringProtocol/slugify()`` makes a slug for a URL. The slug has only
  lowercase ASCII letters, digits and hyphens.

## Compare the Results

This table shows the results of the two methods:

| Title | `sanitizedFilename()` | `slugify()` |
|---|---|---|
| `Swift: Codable / JSON #1` | `Swift Codable JSON 1` | `swift-codable-json-1` |
| `Café ☕️ notes` | `Café ☕️ notes` | `cafe-notes` |
| `日本語のメモ` | `日本語のメモ` | `ri-ben-yunomemo` |
| `😀` | `😀` | `grinning-face` |
| `C++ tips` | `C++ tips` | `c-plus-tips` |
| `  ...  ` | `Untitled` | an empty string |

## Choose a Method

Use ``Swift/StringProtocol/sanitizedFilename(maxLength:fallback:)`` for a
file that people read, for example a note in Obsidian. The method keeps:

- Uppercase and lowercase letters
- Letters with accents and other Unicode letters
- Emoji
- Spaces

Use ``Swift/StringProtocol/slugify()`` for a URL or an identifier in code.
The method changes all letters to lowercase ASCII. It removes accents and
emoji, and it changes spaces to hyphens.

> Note: ``Swift/StringProtocol/slugify()`` is not available on Linux.

## Make a Filename

To make a filename from a title, do these steps:

1. Call ``Swift/StringProtocol/sanitizedFilename(maxLength:fallback:)`` on the
   title.
2. Add the extension to the result.

```swift
let title = "Swift: Codable / JSON #1"
let filename = title.sanitizedFilename() + ".md"
// "Swift Codable JSON 1.md"
```

The method replaces these characters with a space:

- `/` and `\`
- `:`, `*`, `?`, `"`, `<`, `>` and `|`
- `#`, `^`, `[` and `]`. Obsidian does not accept these characters in the name
  of a note.
- Control characters

The method also does these changes:

- It changes the text to Unicode normalization form C (NFC). Then, the same
  title always gives the same filename.
- It removes invisible characters, such as zero-width spaces and bidirectional
  controls.
- It replaces each sequence of whitespace with one space.
- It removes spaces and dots from the start and the end. macOS hides a file if
  its name starts with a dot.

### Length

macOS accepts a filename of 255 bytes or less. By default, the method makes a
filename of 200 UTF-8 bytes or less. This limit keeps space for an extension.
To set a different limit, use the `maxLength` parameter.

The method does not cut a character in two. For example, it does not keep only
a part of an emoji.

### Fallback

If no safe characters remain, the method returns `Untitled`. To set a
different value, use the `fallback` parameter. The method also removes the
characters that are not safe from this value. The result is never empty.

## Topics

### Methods

- ``Swift/StringProtocol/sanitizedFilename(maxLength:fallback:)``
- ``Swift/StringProtocol/slugify()``
