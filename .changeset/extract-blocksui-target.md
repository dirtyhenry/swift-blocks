---
"swift-blocks": minor
---

Extract SwiftUI components (`TaskStateButton`, `PlainDatePicker`, `LabeledTextField`) into a new `BlocksUI` product. `Blocks` is now SwiftUI-free, so command-line consumers no longer need workarounds for the `#Preview` macro. Apps using these views must add a dependency on the `BlocksUI` product and `import BlocksUI`. `PlainDate.date` and `PlainDate.calendar` are now public to support cross-module use from `BlocksUI`.
