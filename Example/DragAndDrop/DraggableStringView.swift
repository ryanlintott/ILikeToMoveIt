//
//  DraggableStringView.swift
//  DragAndDrop
//
//  Created by Ryan Lintott on 2023-07-24.
//

import SwiftUI

struct DraggableStringView: View {
    var body: some View {
        HStack {
            Text("Draggable String:")
            
            
            Text("StringBird")
                .padding()
                .onDrag { NSItemProvider(object: "StringBird" as NSString) }
            
            /// An attempt at a draggable view that works with VoiceOver. It seems to drag but it doesn't drop
//            DraggableView(item: Bird(name: "StringBird"), name: "Bird")
        }
    }
}

struct DraggableStringView_Previews: PreviewProvider {
    static var previews: some View {
        DraggableStringView()
    }
}
