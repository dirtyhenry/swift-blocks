# Read a line of input

Read a line that the user can edit with the arrow keys and the usual shell keys.

## Overview

`Swift.readLine()` uses the line mode of the terminal. In this mode, the arrow keys write escape
sequences such as `^[[D` into the input. ``CLIUtils/editLine(prompt:)`` puts the terminal in raw
mode and reads each key. Thus the user can move the cursor and edit the line.

```swift
import Blocks

do {
    guard let name = try CLIUtils.editLine(prompt: "Name: ") else {
        // The input ended: the user pressed Ctrl-D on an empty line.
        return
    }
    print("Hello, \(name)!")
} catch LineEditorError.interrupted {
    // The user pressed Ctrl-C.
}
```

If the standard input or the standard output is not a terminal, the function uses
`Swift.readLine()`. Thus the same code also reads input from a pipe.

### Keys

| Key | Action |
|---|---|
| Left, Right, Ctrl-B, Ctrl-F | Move the cursor by one character. |
| Alt+Left, Alt+Right, Ctrl+Left, Ctrl+Right | Move the cursor by one word. |
| Home, End, Ctrl-A, Ctrl-E | Move the cursor to the start or to the end of the line. |
| Backspace, Delete | Delete the character before or after the cursor. |
| Ctrl-U, Ctrl-K | Delete the text before or after the cursor. |
| Ctrl-W | Delete the word before the cursor, up to a space. |
| Alt+Backspace | Delete the word before the cursor, up to a character that is not a letter or a digit. |
| Ctrl-D | Delete the character after the cursor. On an empty line, end the input. |
| Ctrl-C | Stop and throw ``LineEditorError/interrupted``. |

### Prompts and long lines

The prompt can contain ANSI styles, for example from ``StyledText``. The styles do not change
the position of the cursor. The prompt can also contain line breaks. The editor writes the lines
before the last line only one time.

The editor shows the line on one row of the terminal. If the line is wider than the terminal, the
line scrolls horizontally.

The editor knows the width of emoji and of East Asian characters. It does not know the width of
all the Unicode characters, so the cursor can be at an incorrect position with some scripts.
