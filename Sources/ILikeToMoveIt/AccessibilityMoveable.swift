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

public struct AccessibilityMove<Item: Hashable>: Hashable {
    public let item: Item
    public let action: AccessibilityMoveAction
}

public class AccessibilityMoveManager<Item: Hashable>: ObservableObject {
    @Published public var focus: Item? = nil
    @Published public var move: AccessibilityMove<Item>? = nil
}

@available(iOS 15, macOS 12, *)
struct AccessibilityMoveableViewModifier<Item: Hashable & Equatable>: ViewModifier {
    @EnvironmentObject var accessibilityMoveManager: AccessibilityMoveManager<Item>
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
                                accessibilityMoveManager.move = .init(item: item, action: action)
                            }
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityFocused($isFocused)
            .onReceive(accessibilityMoveManager.$focus) { newValue in
                if newValue == item {
                    isFocused = true
                }
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

public extension View {
    func accessibilityMoveableIfAvailable<Item: Hashable>(_ item: Item, actions: [AccessibilityMoveAction] = [.up, .down, .toTop, .toBottom]) -> some View {
        if #available(iOS 15, macOS 12, *) {
            return accessibilityMoveable(item, actions: actions)
        } else {
            return self
        }
    }
}

@available(iOS 15, macOS 12, *)
struct AccessibilityMoveableListViewModifier<Item: Hashable>: ViewModifier {
    /// Stores the next accessibility move and the focused item
    @StateObject var accessibilityMoveManager: AccessibilityMoveManager<Item> = .init()
    
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
            accessibilityMoveManager.focus = thisItem
        }
        
        UIAccessibility.post(notification: .announcement, argument: announcement.joined(separator: " "))
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
            return accessibilityMoveableList(items, label: label)
        } else {
            return self
        }
    }
}
