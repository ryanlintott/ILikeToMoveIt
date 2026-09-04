# Changelog

## 0.3.0 - 2026-09-04

### Breaking Changes

- Updated the package to Swift tools 6.0.
- Raised the minimum supported platform from iOS 14 to iOS 15.
- `Providable` now requires `Sendable` conformance. Conforming types that aren't already `Sendable` will need to be made so.

### Added

- DocC documentation catalog with a landing page introducing the package and curating the public API into topic groups.
- Link and badge in the readme pointing to the documentation on the Swift Package Index.
- Swift Package Index configuration for building and hosting the package's DocC documentation.
- Github actions to test Swift 6.0 compatibility, run tests on the current toolchain, and build the package and example app for iOS.
- Added a shared `ILikeToMoveIt.xcworkspace` and `ILikeToMoveIt Development` scheme for package and example-app development.

### Changed

- Removed the `@available(iOS 15, macOS 12, *)` annotations from `accessibilityMoveable(_:actions:)`, `iLikeToMove(_:actions:)`, and `accessibilityMoveableList(_:label:)`. These are now available on every supported platform version, so availability checks around them can be removed.
- Updated readme removing Twitter and adding Bluesky, and matching the section layout used by my other packages.
- The example app now references the package by the `..` relative path instead of `../../ILikeToMoveIt`, so the workspace still resolves if the folder containing the repository is renamed.
- Raised the example app's deployment target from iOS 14 to iOS 15 to match the package.

### Fixed

- Corrected the example app target's product name, which was still `DragAndDrop` after the rename.
- Accessibility moves were held in a published property that was never cleared, because the write that cleared it happened inside the assignment that delivered the move. A view that resubscribed could then have the last move silently applied a second time.
- `.up` and `.down` with a negative distance moved the item in the wrong direction and by the wrong amount, and a very large distance trapped on overflow. Distances are now clamped, so a negative distance moves nothing and a large one moves to the top or bottom.
- `NSItemProvider.loadItem(_:completionHandler:)` never called its completion handler when the provider could not supply any of the item's readable types, leaving callers waiting indefinitely. It now completes with a `ProvidableError.unsupportedUTTypeIdentifier` error and is documented as always calling back exactly once.
- A `Providable` item reported an unstarted `Progress` from a load that had already finished synchronously, leaving the system to believe the load was still in flight.
- `UserActivityProvidable` set `targetContentIdentifier` to the activity type, so every item shared one content identifier and dragging out a second item could target the window already showing the first instead of opening a new one. It now identifies the item, and an activity that cannot be encoded is no longer returned in a state that fails later at decode time.
- Readme corrections: `data(type:)` was shown as `async`, the `onDrop` example omitted the required `isTargeted` argument and so did not compile, the drop and insert examples mutated SwiftUI state off the main actor, and the move announcements described did not match the ones the package emits.
