# Blocks-CLI

A command-line interface for basic proof-of-concepts.

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
   exactly that, with no wrapping `.xcodeproj`. See
   [Building Swift packages with Xcode Cloud][spm-xcc].
2. **A command-line tool cannot produce a Developer ID export.** The Notarize
   post-action runs `xcodebuild -exportArchive` with `method = developer-id`.
   A Command Line Tool target archives to `Products/usr/local/bin/…` rather
   than a single top-level `.app`, which makes it a _generic_ archive that
   cannot be validated or distributed — see [TN3110][tn3110]. The export fails
   with `expected one of {}, but found developer-id`, so
   `CI_DEVELOPER_ID_SIGNED_APP_PATH` is never populated.

Xcode Cloud's notarization support is scoped to macOS **app** archives. Apple's
own guidance for command-line tools is to skip `-exportArchive` and script
notarization manually — see [Customizing the notarization workflow][custom-notary].

Working around this inside Xcode Cloud is also a dead end: its build keychain
holds no Developer ID identity, and it deletes any file a custom
`ci_post_xcodebuild.sh` creates.

### If notarization is ever needed

Do it outside Xcode Cloud, from a Makefile target or a GitHub Actions release
workflow: `swift build -c release` → `codesign --options runtime --timestamp`
→ package → `xcrun notarytool submit --wait` → `xcrun stapler staple`. Note
that a bare Mach-O executable cannot be stapled, so the ticket has to be
stapled to a container (`.pkg` or `.dmg`); a zipped binary notarizes fine but
relies on an online Gatekeeper check at first launch.

[spm-xcc]:
  https://developer.apple.com/documentation/xcode/building-swift-packages-or-swift-playground-app-projects-with-xcode-cloud
[tn3110]:
  https://developer.apple.com/documentation/technotes/tn3110-resolving-generic-xcode-archive-issue
[custom-notary]:
  https://developer.apple.com/documentation/security/customizing-the-notarization-workflow
