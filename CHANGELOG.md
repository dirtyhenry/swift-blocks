## 0.5.0 (2024-09-30)

### Feat

- **app**: make slugify form look better on macOS
- **demo**: add slugify demo in app
- **slugify**: custom support of plus sign character
- **slugify**: iterate with more use cases and tests
- **cli**: add slugify command to the CLI
- **extensions**: add slugify command to StringProtocol
- **cli**: add merge JSON command
- copy files from legacy app Martinet
- add scaffold for legacy Martinet app

### Fix

- release build would break
- **ci**: release build should not use debugging extensions

### Refactor

- DRY code to address JSCPD linting warning

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

- Add ways to list XCode devices as a CLI command and a CI script;
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

[1]: https://bootstragram.com/blog/slugify-in-swift/
[2]: https://micro.mickf.net/2024/09/30/a-simple-workflow.html
[3]: https://bootstragram.com/blog/blocks-and-hoods/
[4]: https://en.wikipedia.org/wiki/Martinet
