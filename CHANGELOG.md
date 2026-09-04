# Changelog

## 0.3.0 - 2026-09-03

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
