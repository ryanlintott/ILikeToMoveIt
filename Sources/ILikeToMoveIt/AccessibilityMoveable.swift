//
//  AccessibilityMoveable.swift
//  ILikeToMoveIt
//
//  Created by Ryan Lintott on 2023-06-28.
//

import SwiftUI

public enum AccessibilityMoveAction: Identifiable, Hashable, Equatable {
    case up(Int = 1)
    case down(Int = 1)
    case toTop
    case toBottom

    public var id: Self { self }
}

public extension AccessibilityMoveAction {
    static let up: Self = .up()
    static let down: Self = .down()

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

public struct AccessibilityFocusedItemKey: EnvironmentKey {
    public static let defaultValue: (any Hashable)? = nil
}

public struct AccessibilityMoveKey: EnvironmentKey {
    public static let defaultValue: ((any Hashable, AccessibilityMoveAction) -> Void)? = nil
}

public extension EnvironmentValues {
    var accessibilityFocusedItem: (any Hashable)? {
        get { self[AccessibilityFocusedItemKey.self] }
        set { self[AccessibilityFocusedItemKey.self] = newValue }
    }
    
    var accessibilityMove: ((_ item: any Hashable, _ action: AccessibilityMoveAction) -> Void)? {
        get { self[AccessibilityMoveKey.self] }
        set { self[AccessibilityMoveKey.self] = newValue }
    }
}

@available(iOS 15, macOS 12, *)
struct AccessibilityMoveableViewModifier<Item: Hashable & Equatable>: ViewModifier {
    @Environment(\.accessibilityFocusedItem) var accessibilityFocusedItem
    @Environment(\.accessibilityMove) var accessibilityMove
    @AccessibilityFocusState var isFocused: Bool
    
    let item: Item
    let actions: [AccessibilityMoveAction]
    
    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .background {
                ZStack {
                    ForEach(actions) { action in
                        Color.clear
                            .accessibilityAction(named: action.name) {
                                accessibilityMove?(item, action)
                            }
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .onChange(of: accessibilityFocusedItem as? Item) { newValue in
                isFocused = newValue == item
            }
    }
}

@available(iOS 15, macOS 12, *)
public extension View {
    func accessibilityMoveable<Item: Hashable>(_ item: Item, actions: [AccessibilityMoveAction] = [.up, .down, .toTop, .toBottom]) -> some View {
        modifier(AccessibilityMoveableViewModifier(item: item, actions: actions))
    }
    
    func iLikeTo<It: Hashable>(move it: It, _ actions: [AccessibilityMoveAction] = [.up, .down, .toTop, .toBottom]) -> some View {
        accessibilityMoveable(it, actions: actions)
    }
}

@available(iOS 15, macOS 12, *)
struct AccessibilityMoveableListViewModifier<Item: Hashable>: ViewModifier {
    /// Stores the state of the focused list item
    @State var focus: Item? = nil
    
    @Binding var items: [Item]
    
    /// Keypath for the label of each item, used when describing items above and below the moved item.
    let label: KeyPath<Item, String>?
    
    func body(content: Content) -> some View {
        content
            .environment(\.accessibilityFocusedItem, focus)
            .environment(\.accessibilityMove) { item, action in
                guard
                    let item = item as? Item,
                    let itemIndex = items.firstIndex(of: item),
                    items.count > 1
                else { return }

                var destinationIndex: Int

                switch action {
                case let .up(distance):
                    destinationIndex = items.index(itemIndex, offsetBy: -distance)
                case let .down(distance):
                    destinationIndex = items.index(itemIndex, offsetBy: distance + 1)
                case .toTop:
                    destinationIndex = items.startIndex
                case .toBottom:
                    destinationIndex = items.endIndex
                }
                /// Clamp destination by start and end index
                destinationIndex = min(max(items.startIndex, destinationIndex), items.endIndex)

                let thisItem = item
                var announcement = [String]()

                switch (destinationIndex, action) {
                case (itemIndex, .up), (itemIndex, .toTop), (itemIndex + 1, .down), (itemIndex + 1, .toBottom):
                    announcement.append("Not moved.")
                case (itemIndex - 1, .up):
                    announcement.append("Moved up.")
                case (itemIndex + 2, .down):
                    announcement.append("Moved down.")
                case (_, .up), (_, .toTop):
                    announcement.append("Moved up by \(itemIndex - destinationIndex).")
                case (_, .down), (_, .toBottom):
                    announcement.append("Moved down by \(destinationIndex - itemIndex).")
                }
                
                if let label {
                    switch (destinationIndex, action) {
                    case (itemIndex, .up), (itemIndex, .toTop), (itemIndex + 1, .down), (itemIndex + 1, .toBottom):
                        break
                    case (_, .up), (_, .toTop):
                        announcement.append("Above \(items[destinationIndex][keyPath: label]).")
                    case (_, .down), (_, .toBottom):
                        announcement.append("Below \(items[destinationIndex - 1][keyPath: label]).")
                    }
                }

                switch destinationIndex {
                case items.startIndex:
                    announcement.append("Item at top.")
                case items.endIndex:
                    announcement.append("Item at bottom.")
                default:
                    break
                }

                if destinationIndex != itemIndex {
                    items.move(fromOffsets: [itemIndex], toOffset: destinationIndex)
                    /// Even though accessibility focus appears to stay on the moved item, resetting it ensures the index and associated accessibility actions are also updated.
                    focus = thisItem
                }

                UIAccessibility.post(notification: .announcement, argument: announcement.joined(separator: " "))
            }
    }
}

@available(iOS 15, macOS 12, *)
public extension View {
    func accessibilityMoveableList<Item: Hashable>(_ items: Binding<Array<Item>>, label: KeyPath<Item, String>? = nil) -> some View {
        modifier(AccessibilityMoveableListViewModifier(items: items, label: label))
    }
}

public extension View {
    func accessibilityMoveableListIfAvailable<Item: Hashable>(_ items: Binding<Array<Item>>, label: KeyPath<Item, String>? = nil) -> some View {
        if #available(iOS 15, macOS 12, *) {
            return modifier(AccessibilityMoveableListViewModifier(items: items, label: label))
        } else {
            return self
        }
    }
}
