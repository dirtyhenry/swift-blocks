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

An initial version. A non-empty starting point.
