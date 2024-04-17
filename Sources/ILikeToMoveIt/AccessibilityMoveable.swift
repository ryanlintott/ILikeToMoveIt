//
//  AccessibilityMoveable.swift
//  ILikeToMoveIt
//
//  Created by Ryan Lintott on 2023-06-28.
//

import SwiftUI

/// Options for moving an item up and down a SwiftUI list using accessibility actions.
public enum AccessibilityMoveAction: Identifiable, Hashable, Sendable {
    /// Move up by some number of spaces.
    case up(Int = 1)
    /// Move down by some number of spaces.
    case down(Int = 1)
    /// Move to the top of the list.
    case toTop
    /// Move to the bottom of the list.
    case toBottom

    public var id: Self { self }
    
    /// True if up or isTop
    var isMovingUp: Bool {
        switch self {
        case .up(_), .toTop: true
        case .down(_), .toBottom: false
        }
    }
}

public extension AccessibilityMoveAction {
    /// Move up by one.
    static let up: Self = .up()
    /// Move down by one.
    static let down: Self = .down()

    /// Name of the accessibility action
    var name: String {
        switch self {
        case .up(by: 1):
            return "Move up"
        case .down(by: 1):
            return "Move down"
        case .up(let int):
            return "Move up by \(int)"
        case .down(let int):
            return "Move down by \(int)"
        case .toTop:
            return "Move to top"
        case .toBottom:
            return "Move to bottom"
        }
    }
}

/// An item and a move action to be applied to that item in a list.
public struct AccessibilityMove<Item: Hashable>: Hashable {
    /// Item to move
    public let item: Item
    /// Move action to apply to item.
    public let action: AccessibilityMoveAction
}

/// An observable object that holds information about the current accessibility move and focus.
@MainActor
public class AccessibilityMoveController<Item: Hashable>: ObservableObject {
    /// The current accessibility item to focus on.
    @Published public var focus: Item? = nil
    /// The current accessibility move to perform.
    @Published public var move: AccessibilityMove<Item>? = nil
}

/// A View Modifier that adds accessibility move actions that allow a user to move the item up and down in a list.
///
/// Requires a single `AccessibilityMoveableListViewModifier` on a parent view to apply accessibility move actions.
@available(iOS 15, macOS 12, *)
@MainActor
struct AccessibilityMoveableViewModifier<Item: Hashable & Equatable>: ViewModifier {
    @EnvironmentObject var accessibilityMoveController: AccessibilityMoveController<Item>
    /// Focus state can only be managed inside a single SwiftUI View so it lives on each item and gets updated via the environment object.
    @AccessibilityFocusState var isFocused: Bool
    
    let item: Item
    let actions: [AccessibilityMoveAction]
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    ForEach(actions) { action in
                        Color.clear
                            .accessibilityAction(named: action.name) {
                                accessibilityMoveController.move = .init(item: item, action: action)
                            }
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityFocused($isFocused)
            .task {
                /// This ensures the accessibility focus is set when the view appears as well as when the focus changes.
                if accessibilityMoveController.focus == item {
                    print("View appeared and focus set for \(String(describing: item))")
                    isFocused = true
                }
            }
            .onReceive(accessibilityMoveController.$focus) { newValue in
                if newValue == item {
                    print("Value changed and focus set for \(String(describing: newValue))")
                    isFocused = true
                }
            }
    }
}

@available(iOS 15, macOS 12, *)
public extension View {
    /// Adds accessibility move actions that allow a user to move the item up and down in a list.
    ///
    /// Requires a single `.accessibilityMoveableList` modifier applied to a parent view (typically `List`)
    /// - Parameters:
    ///   - item: The item to move.
    ///   - actions: An array of move actions made available to the user.
    /// - Returns: A view of an item that can be moved up and down in a list via accessibility actions.
    @MainActor
    func accessibilityMoveable<Item: Hashable>(_ item: Item, actions: [AccessibilityMoveAction] = [.up, .down, .toTop, .toBottom]) -> some View {
        modifier(AccessibilityMoveableViewModifier(item: item, actions: actions))
    }
    
    /// Adds accessibility move actions that allow a user to move the item up and down in a list.
    ///
    /// Requires a single `.accessibilityMoveableList` modifier applied to a parent view (typically `List`)
    /// Alternatively-named function for `accessibilityMoveable`
    /// - Parameters:
    ///   - it: The item to move.
    ///   - actions: An array of move actions made available to the user.
    /// - Returns: A view of an item that can be moved up and down in a list via accessibility actions.
    @MainActor
    func iLikeToMove<It: Hashable>(_ it: It, actions: [AccessibilityMoveAction] = [.up, .down, .toTop, .toBottom]) -> some View {
        accessibilityMoveable(it, actions: actions)
    }
}

/// A View Modifier that applies accessibility move actions from child views that use `AccessibilityMoveableViewModifier`
@available(iOS 15, macOS 12, *)
@MainActor
struct AccessibilityMoveableListViewModifier<Item: Hashable>: ViewModifier {
    /// Stores the next accessibility move and the focused item
    @StateObject var accessibilityMoveManager: AccessibilityMoveController<Item> = .init()
    
    @Binding var items: [Item]
    
    /// Keypath for the label of each item, used when describing items above and below the moved item.
    let label: KeyPath<Item, String>?
    
    func body(content: Content) -> some View {
        content
            .environmentObject(accessibilityMoveManager)
            .onReceive(accessibilityMoveManager.$move) { newValue in
                guard let newValue else { return }
                move(newValue)
                accessibilityMoveManager.move = nil
            }
    }
    
    func move(_ accessibilityMove: AccessibilityMove<Item>) {
        let item = accessibilityMove.item
        let action = accessibilityMove.action
        guard
            let itemIndex = items.firstIndex(of: item),
            items.count > 1
        else { return }
        
        var destinationIndex: Int
        
        switch action {
        case let .up(distance):
            destinationIndex = items.index(itemIndex, offsetBy: -distance)
        case let .down(distance):
            destinationIndex = items.index(itemIndex, offsetBy: distance)
        case .toTop:
            destinationIndex = items.startIndex
        case .toBottom:
            destinationIndex = items.endIndex - 1
        }
        /// Clamp destination by start and end index
        destinationIndex = min(max(items.startIndex, destinationIndex), items.endIndex - 1)
        
        let thisItem = item
        var announcement = [String]()
        
        switch (destinationIndex, action) {
        case (itemIndex, _):
            announcement.append("Not moved.")
        case (itemIndex - 1, .up):
            announcement.append("Moved up.")
        case (itemIndex + 1, .down):
            announcement.append("Moved down.")
        case (_, .up), (_, .toTop):
            announcement.append("Moved up by \(itemIndex - destinationIndex).")
        case (_, .down), (_, .toBottom):
            announcement.append("Moved down by \(destinationIndex - itemIndex).")
        }
        
        if let label {
            switch (destinationIndex, action) {
            case (itemIndex, _):
                break
            case (_, .up), (_, .toTop):
                announcement.append("Above \(items[destinationIndex][keyPath: label]).")
            case (_, .down), (_, .toBottom):
                announcement.append("Below \(items[destinationIndex][keyPath: label]).")
            }
        }
        
        switch destinationIndex {
        case items.startIndex:
            announcement.append("Item at top.")
        case items.endIndex - 1:
            announcement.append("Item at bottom.")
        default:
            break
        }
        
        if destinationIndex != itemIndex {
            items.move(fromOffsets: [itemIndex], toOffset: destinationIndex + (action.isMovingUp ? 0 : 1))
            /// Even though accessibility focus appears to stay on the moved item, resetting it ensures the index and associated accessibility actions are also updated.
            accessibilityMoveManager.focus = thisItem
        }
        
        /// This may be a bug in Swift 5.10
        /// https://forums.swift.org/t/preconcurrency-notification-names-in-submodules/70514
        UIAccessibility.post(notification: .announcement, argument: announcement.joined(separator: " "))
    }
}

@available(iOS 15, macOS 12, *)
public extension View {
    /// Applies accessibility move actions from child views that use `accessibilityMoveable`
    /// - Parameters:
    ///   - items: Array of items that will be modified by accessibility move actions.
    ///   - label: Optional keypath to the name of an item. If used, the names of items that are directly below a move up or above a move down will be annouced after a move.
    /// - Returns: A view that applies accessibility move actions from child views.
    @MainActor
    func accessibilityMoveableList<Item: Hashable>(_ items: Binding<Array<Item>>, label: KeyPath<Item, String>? = nil) -> some View {
        modifier(AccessibilityMoveableListViewModifier(items: items, label: label))
    }
}
