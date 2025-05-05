## 0.7.0

### Minor Changes

- 17c901b: Iterate on `CLIUtils.shell` command.

  ⚠️ The signature now throws:

  ```diff
  -static func shell(_ command: String) -> String
  +static func shell(_ command: String) throws -> String
  ```

### Patch Changes

- 995be85: Stop escaping slashes on `JSON` functions.

  Output examples:

  ```diff
  -foo\/bar
  +foo/bar
  ```

## 0.6.0 (2024-12-30)

### Feat

- **Swift 6 compatibility.** This was easier than I expected. The only challenge
  I faced (so far?) was creating a convenient utility to detect if a device is
  connected to an Apple Watch, which I (temporarily?) removed from the library
  and the demo.
- **`LabeledTextField` and Demo Form.** Forms can be challenging in SwiftUI, as
  their appearance may be off-putting at first. To address this, I began using
  Blocks to create custom form components and tested them in a playground to
  ensure my forms look great on both iOS and macOS, which is often overlooked.
- **Transport Demo.** Transport features are the ones I use most in the apps
  built on these Blocks. I added a long-overdue demo to help users understand
  them more easily.
- **Misc.** An `.average()` function for collections of numbers (as generic as
  possible), a `yearWeek` property on `PlainDate`, and some Objective-C
  memorabilia.

## 0.5.0 (2024-09-30)

- **Slug creation tool.** A `slugify` function for strings, or anything
  conforming to `StringProtocol`, has been added. There's a demo available in
  the example app, and the function is also accessible through the CLI. I wrote
  [a blog article][1] that explains in detail the requirements, the
  implementation, and provides examples—including emoji characters and various
  alphabets.
- **JSON dictionary merging tool.** A new CLI command can now merge two files
  containing simple string-to-string dictionary objects. [Why might you need
  this?][2]
- **Imported legacy demo app.** This repository is my latest attempt to collect
  useful Swift code for reuse across projects, demos, and proof-of-concepts.
  Learn more about [why `swift-blocks` is already a successful effort][3]. I
  also imported a previous project called Martinet—named after the swift bird in
  French, _not_ [the punishment tool for misbehaving children][4]—as part of
  consolidating my GitHub repositories to reduce maintenance. While it includes
  some legacy features, it brings back fond memories and could be useful in the
  future.

## 0.4.0 (2024-06-21)

### Feat

- **poc**: add a little experiement using os logging
- **cli**: add new barcode generation command
- **transport**: add Linux compatibility
- **transport**: add RetryTransport
- **ui**: add alignment to TaskStateButton
- **ui**: add default action for TaskStateButton
- add date function to JavaScriptISO8601DateFormatter
- **web**: add OpenGraph and FrontMatter structs
- **ci**: improve error output of ListDevices

### Fix

- Linux build
- macOS build
- bump CLI version number

### Refactor

- **tests**: lint and improve
- use leaner style

## 0.3.0 (2024-03-21)

### Feat

- Add ways to list Xcode devices as a CLI command and a CI script;
- New project icon
- Add `Bundle` extension syntactic sugar to load `Data` and `String` contents
- Add `CopyUtils` to lint copy text
- Start handling colors in CLI utils
- `MailtoComponents` now conforms to `Equatable` (for TCA usage)
- Improve the macOS app layout
- Add `allFontNames` extension for `AppKit`
- Add `Pasteboard` utility struct
- Iterate on `TaskStateButton`
- Add new `PlainDatePicker` SwiftUI component (with demo)
- Fix Linux support
- Improve usability of `MockTransport`
- Use `URLRequestHeaderItem` in Endpoint

## 0.2.0 (2023-12-23)

### BREAKING CHANGE

- MandatoryTaskState was renamed TaskState.

### Feat

- Introduce Objective-C library as a new home for older endeavours
- Add PKCE code from an old blog post
- Introduce URLRequestHeaderItem
- Add TaskStateButton
- Add CLIUtils to read input securely in CLI
- Read barcode command
- WrongStatusCodeError conforms to LocalizedError
- Add background activity experiment
- Add UIFont extension and fonts view in demo app
- Add a modified version of TinyNetworking
- Add logging transport
- Add JSON util functions to format JSON
- Improve keychain error support
- Add MailtoComponents with demo
- Support name and description in calendars
- Add Multipart request utility

### Refactor

- Rename DateString to PlainDate
- Rewrite iCal using result builder

## 0.1.0 (2023-07-27)

- 🐛 macOS version now compiles without error or warning

### Refactor

- 💡 Renaming swift-blocks
- 💡 Linting and cleaning up useless edits
- 💡 Move utility to Blocks and import it in the app

- Is this the right URL?

[1]: https://mickf.net/tech/slugify-in-swift/
[2]: https://micro.mickf.net/2024/09/30/a-simple-workflow.html
[3]: https://mickf.net/tech/blocks-and-hoods/
[4]: https://en.wikipedia.org/wiki/Martinet
