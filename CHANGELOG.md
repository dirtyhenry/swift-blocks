## 0.3.0 (2024-03-21)

### Feat

- **ci**: use list device script
- **ci**: enhance CI scripting test
- **ci**: add hello world script
- **spm**: add cli product to manifest
- **cli**: add super version of 'xcrun simctl list devices'
- **design**: update icon
- 🎸 Add Bundle extension to load contents
- 🎸 Add CopyUtils to lint copy text
- 🎸 Start handling colors in CLI utils
- 🎸 MailtoComponents now conforms to Equatable
- 🎸 proper macOS app with font search
- 🎸 Add allFontNames extension for AppKit
- 🎸 Create Pasteboard utility struct
- 🎸 Iterate on TaskStateButton
- 🎸 Add demo of PlainDatePicker
- 🎸 Add new PlainDatePicker SwiftUI component
- 🎸 Globally exclude ObjC product and targets for Linux
- 🎸 Reinstate Linux as a target
- 🎸 Improve usability of MockTransport
- 🎸 Use URLRequestHeaderItem in Endpoint

### Fix

- use main branch for CI scripts
- **ci**: checkout before running scripts
- **blocks**: only macOS can provide shell extension
- 🐛 Build for watchOS and tvOS
- 🐛 Refactor to prevent empty space suffix

### Refactor

- 💡 Cleanup unused class

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
