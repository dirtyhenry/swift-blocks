# Front Matter for Markdown Files

Write a YAML front matter block for a Markdown file.

## Overview

Markdown tools such as Jekyll and Obsidian read metadata from a front matter
block. This block is at the start of the file. It starts and ends with a `---`
line. Each line between them has a key and a value.

``FrontMatterEncoder`` writes this block from an `Encodable` value. It does not
use a YAML library.

## Write a Front Matter Block

To write a front matter block, do these steps:

1. Make a struct that conforms to `Encodable`.
2. Add one property for each key.
3. Give the value to ``FrontMatterEncoder/encode(_:)``.

```swift
struct Note: Encodable {
    let title: String
    let date: PlainDate
    let tags: [String]
    let draft: Bool
}

let note = Note(
    title: #"Swift: "Codable" tips #1"#,
    date: "2026-10-27",
    tags: ["swift", "yaml"],
    draft: false
)
let frontMatter = try FrontMatterEncoder().encode(note)
```

The encoder returns this text:

```yaml
---
title: "Swift: \"Codable\" tips #1"
date: 2026-10-27
tags: ["swift", "yaml"]
draft: false
---
```

The keys are in the same order as the properties of the struct. The text ends
with a line break. Put the Markdown content after it.

## Values

The encoder writes each type of value as follows:

| Swift type | YAML value | Example |
|---|---|---|
| `String` | JSON string | `"Say \"hi\""` |
| `Int` and other integer types | Number | `42` |
| `Bool` | Boolean | `true` |
| ``PlainDate`` | Date, as `YYYY-MM-DD` | `2026-10-27` |
| `URL` | JSON string | `"https://example.com"` |
| Array of the types above | Flow sequence | `["swift", "yaml"]` |

An enumeration with a raw value of one of these types is also correct. The
encoder writes its raw value.

The encoder does not write a key when its value is `nil`.

### Strings

The encoder writes each string as a JSON string. A JSON string is also a
correct YAML string. For this reason, these characters do not cause errors in
the block:

- Quotation marks and backslashes
- Colons (`:`) and number signs (`#`)
- A hyphen at the start of a string (`- `)
- Line breaks
- Emoji
- Control characters

Words such as `yes`, `no` or `null` stay strings. A YAML parser does not change
them to Boolean or empty values.

### Keys

The encoder uses the names of the properties as keys. It puts quotation marks
around a key if YAML can read the key as a different value. For example, YAML
can read the key `on` as a Boolean.

## Values That the Encoder Does Not Accept

The front matter must be flat. The encoder does not accept these values:

- A struct or a dictionary in a property
- An array in an array
- A floating-point number, such as `Double`
- A `Date`. Use ``PlainDate`` for a date.

For these values, the encoder throws
``FrontMatterEncodingError/unsupportedValue(key:)``. The error gives the key of
the value.

The value that you give to the encoder must have keys. If you give an array or
a single value, the encoder throws ``FrontMatterEncodingError/notKeyed``.

Each key must occur one time only. A custom `encode(to:)` implementation can
write a key two times. In this case, the encoder throws
``FrontMatterEncodingError/duplicateKey(_:)``.

> Note: Use a YAML library if you must write nested values.

## Topics

### Front Matter Encoder

- ``FrontMatterEncoder``
- ``FrontMatterEncodingError``
