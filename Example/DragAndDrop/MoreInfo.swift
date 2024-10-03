//
//  MoreInfo.swift
//  DragAndDrop
//
//  Created by Ryan Lintott on 2023-07-10.
//

import SwiftUI

struct MoreInfo: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("What is this?")) {
                    Text("This app is a demo app for SwiftUI drag and drop features using iLikeToMoveIt extensions.")
                }
                
                Section(header: Text("Using Providable or Transferable you can:")) {
                    Text("Drag items to reorder.")
                    Text("Drag from one list to another.")
                    Text("While dragging tap to add additional items.")
                    Text("Drag string into list.")
                    Text("Drag strings from any app.")
                    Text("Enable VoiceOver and use move actions to move items up, down, to the top and to the bottom of the list. (iOS 15+ only. dragging between lists and apps not yet supported)")
                }
                
                Section(header: Text("Using Providable you can:")) {
                    Text("Drag items to make a new window on iPadOS (iOS 16+ only)")
                }
            }
            .navigationTitle("You like to move it?")
            .toolbar {
                ToolbarItem {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
        }
    }
}

struct MoreInfo_Previews: PreviewProvider {
    struct PreviewData: View {
        @State private var isShowingMoreInfo = true
        
        var body: some View {
            Color.clear
                .sheet(isPresented: $isShowingMoreInfo) {
                    MoreInfo()
                }
        }
    }
    
    static var previews: some View {
        PreviewData()
    }
}
