//
//  BirdListTransferable.swift
//  DragAndDrop
//
//  Created by Ryan Lintott on 2023-05-25.
//

import ILikeToMoveIt
import SwiftUI

@available(iOS 16, macOS 13, *)
struct BirdListTransferable: View {
    @Binding var birds: [Bird]
    @State private var isEmptyListTargeted = false
    
    var body: some View {
        if birds.isEmpty {
            Color.gray
                .opacity(isEmptyListTargeted ? 0.5 : 1)
                /// A label is added so that this view can be selected and used as a drop point. Without the label there would not be a way to focus this view and use it as a drop point.
                .accessibilityLabel("Empty List")
                .dropDestination(for: Bird.self) { droppedBirds, location in
                    birds.append(contentsOf: droppedBirds)
                    return true
                } isTargeted: {
                    isEmptyListTargeted = $0
                }
        } else {
            List {
                ForEach(birds) { bird in
                    VStack {
                        Text(bird.name)
                        Text("id: \(bird.id.uuidString)")
                            .font(.caption2)
                            .lineLimit(1)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityHint("id: \(bird.id.uuidString)")
                    .accessibilityMoveable(bird, actions: [.up, .down, .up(3), .down(3), .toTop, .toBottom])
                    /// This drag point modifier does nothing inside a List view.
//                    .accessibilityDragPoint(.center, description: "Drag \(bird.name)")
                    /// This allows accessible dropping of items in the list. I have attempted adding a drop point aligned to .top and .bottom to drop above and below the item but the alignment does not correspond to the order in the list in any consistent way.
                    .accessibilityDropPoint(.center, description: "Drop")
                    /// This draggable modifier will not add a "drag" accessibility action. It will however allow adding this element to an existing drag session via the "activate" action.
                    .draggable(bird)
                }
                .onMove {
                    birds.move(fromOffsets: $0, toOffset: $1)
                }
                .onDelete {
                    birds.remove(atOffsets: $0)
                }
                .dropDestination(for: Bird.self) { droppedBirds, offset in
                    /// only add birds with new unique ids
                    let newBirds = droppedBirds.filter { bird in
                        !birds.contains { $0.id == bird.id }
                    }
                    birds.insert(contentsOf: newBirds, at: offset)
                }
            }
            .accessibilityMoveableList($birds, label: \.name)
        }
    }
}

@available(iOS 16, macOS 13, *)
struct BirdListTransferable_Previews: PreviewProvider {
    static var previews: some View {
        BirdListTransferable(birds: .constant(Bird.examples))
    }
}
