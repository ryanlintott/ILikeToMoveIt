<picture>
  <source srcset="https://github.com/ryanlintott/ILikeToMoveIt/assets/2143656/fb28d9e9-7e1c-4c05-9f00-130daf64a513" media="(prefers-color-scheme: dark)">
  <img width="600" src="https://github.com/ryanlintott/ILikeToMoveIt/assets/2143656/e7df51f5-f74a-4d3e-ad03-a13b77c305a9">
</picture>


[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FILikeToMoveIt%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanlintott/ILikeToMoveIt)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FILikeToMoveIt%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanlintott/ILikeToMoveIt)
![License - MIT](https://img.shields.io/github/license/ryanlintott/ILikeToMoveIt)
![Version](https://img.shields.io/github/v/tag/ryanlintott/ILikeToMoveIt?label=version)
![GitHub last commit](https://img.shields.io/github/last-commit/ryanlintott/ILikeToMoveIt)
[![Mastodon](https://img.shields.io/badge/mastodon-@ryanlintott-5c4ee4.svg?style=flat)](http://mastodon.social/@ryanlintott)
[![Twitter](https://img.shields.io/badge/twitter-@ryanlintott-blue.svg?style=flat)](http://twitter.com/ryanlintott)

# Overview
- Add [accessible move actions](#accessibilitymoveable) to any array of items in a SwiftUI List or ForEach.
- Make drag-and-drop operations easier for custom types in iOS 14 and 15 using [`Providable`](#providable)
- Make drag-to-create-a-new-window operations easier in iPadOS using [`UserActivityProvidable`](#useractivityprovidable)

# DragAndDrop (example app)
Check out the [example app](https://github.com/ryanlintott/DragAndDrop) to see how you can use this package in your iOS app.

# Installation and Usage
1. In Xcode go to `File -> Add Packages`
2. Paste in the repo's url: `https://github.com/ryanlintott/ILikeToMoveIt` and select by version.
3. Import the package using `import ILikeToMoveIt`

# Platforms
This package is compatible with iOS 14+ but the accessibility move feature only works for iOS 15+.

# Support iLikeToMoveIt
If you like this package, buy me a coffee to say thanks!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/X7X04PU6T)

Or you can buy a t-shirt with the iLikeToMoveIt logo

<a href="https://cottonbureau.com/p/44WXMN/shirt/i-like-to-move-it#/18025527"><img width="256" alt="ShapeUp T-Shirt" src="https://cottonbureau.com/mockup?vid=18025527&hash=1055&w=512"></a>

- - -
# Details
## AccessibilityMoveable
*\*iOS 15+*

Two modifiers are required to enable accessible move actions. One for each item and one for the list itself.

```swift
List {
  ForEach(items) { item in
    Text(item.name)
      .accessibilityMoveable(item)
  }
}
.accessibilityMoveableList($items, label: \.name)
```

### `.accessibilityMoveable`
Adding this modifier will add accessibility actions to move the item up, down, to the top of the list and to the bottom. If you want to customize these actions you can supply your own array.

Example: If you have a short list and only want up and down.
```swift
.accessibilityMoveable(item, actions: [.up, .down])
```

Example: If you have a long list and want options to move items more than one step at a time.
```swift
.accessibilityMoveable(item, actions: [.up, .down, .up(5), .down(5), .toTop, .toBottom])
```

When the user triggers an accessibility action the following results are reported back via a UIAccessibility announcement:
- "moved up", "moved down", or "not moved"
- "by [number of spaces]" if moved by more than one space.
- "above [item label]" if moved down and "below [item label]" if moved up. Only if a label keypath is was provided.
- "At top" or "At bottom" if at the top or bottom of the list.

### `.accessibilityMoveableList`
This modifier applies the changes from the move actions to the list and adjusts the accessibility focus to ensure it stays on the correct item.

You pass in a binding to the array of items and an optional label keypath. This label will be read out after moving an item to let the user know what item is directly below after moving up or directly above after moving down.

```swift
.accessibilityMoveableList($items, label: \.name)
```

### Known issues
- Moving the same item again immediately after moving it may cause the accessibility focus to lag and another item will be moved instead.

## Providable
This protocol allows for easier drag and drop for `Codable` objects in iOS 14 and 15

Drag and drop operations were made much easier in iOS 16 by the `Transferable` protocol. Older methods use `NSItemProvider` and were cumbersome to set up.

### How to use it
Conform your object to `Providable`. Add readable and writable types, then add functions to transform your object to and from those types.
```swift
extension Bird: Providable {
    static let writableTypes: [UTType] = [.bird]

    static let readableTypes: [UTType] = [.bird, .plainText]

    func data(type: UTType) async throws-> Data? {
        switch type {
        case .bird:
            return try JSONEncoder().encode(self)
        default:
            return nil
        }
    }

    init?(type: UTType, data: Data) throws {
        switch type {
        case .bird:
            self = try JSONDecoder().decode(Bird.self, from: data)
        case .plainText:
            let string = String(decoding: data, as: UTF8.self)
            self = Bird(name: string)
        default:
            return nil
        }
    }
}
```

You will need to add any custom types to your project.
Project > Target > Info > ExportedTypeIdentifiers

### Adding drag and drop operations

Add a drag option to a view like this:
```swift
.onDrag { bird.provider }
```

And a drop option like this:
```swift
.onDrop(of: Bird.readableTypes) { providers, location in
  providers.loadItems(Bird.self) { bird, error in
    if let bird {
        birds.append(bird)
    }
  }
  return true
}
```

And even an insert option like this:
```swift
.onInsert(of: Bird.readableTypes) { index, providers in
  providers.loadItems(Bird.self) { bird, error in
    if let bird {
      birds.insert(bird, at: index)
    }
  }
}
```

## UserActivityProvidable
Extension to the `Providable` protocol to add easy drag to new window (a feature not supported by `Transferable`) on iPadOS 16+

Add your activity type string to plist under `NSUserActivityTypes` and then add the same string to the activityType parameter on your codable type.

```swift
extension Bird: UserActivityProvidable {
  static let activityType = "com.ryanlintott.draganddrop.birdDetail"
}
```

Use the `onContinueUserActivity` overload function that takes a `UserActivityProvidable` object to handle what your app does when opened via this activity.

```swift
.onContinueUserActivity(Bird.self) { bird in
  /// Adjust state based on your object.
}
```

You can also target a separate WindowGroup for your object. Make sure you still use `onContinueUserActivity` in your view to ensure the object gets loaded.

```swift
WindowGroup {
  BirdDetailView()            
}
.handlesExternalEvents(matching: [Bird.activityType])
```
