# ``ILikeToMoveIt``

Accessible list reordering and easier drag and drop for SwiftUI.

## Overview

ILikeToMoveIt does two things.

It adds accessibility move actions to any array of items in a SwiftUI `List` or `ForEach`, so VoiceOver users can move an item up, down, to the top, or to the bottom without dragging. Apply one modifier to each item and one to the list:

```swift
List {
    ForEach(items) { item in
        Text(item.name)
            .accessibilityMoveable(item)
    }
}
.accessibilityMoveableList($items, label: \.name)
```

It also makes `NSItemProvider` drag and drop easier for custom `Codable` types through ``Providable``. Declare the types your object reads and writes, convert to and from `Data`, and the protocol supplies the `NSItemProvider` that `onDrag`, `onDrop`, and `onInsert` need:

```swift
extension Bird: Providable {
    static let writableTypes: [UTType] = [.bird]
    static let readableTypes: [UTType] = [.bird, .plainText]
}

Text(bird.name)
    .onDrag { bird.provider }
```

``UserActivityProvidable`` extends that to dragging an object out to a new window on iPadOS, a feature `Transferable` doesn't cover.

Requires iOS 15+.

For a feature-by-feature guide with examples, see the [README](https://github.com/ryanlintott/ILikeToMoveIt), and the `Example` folder in the [repository](https://github.com/ryanlintott/ILikeToMoveIt) for a demo app.

## Topics

### Accessible Moving

- ``AccessibilityMoveAction``
- ``AccessibilityMove``
- ``AccessibilityMoveController``

### Drag and Drop

- ``Providable``
- ``UserActivityProvidable``

### Errors

- ``ProvidableError``
