//
//  ILikeToMoveItExampleApp.swift
//  ILikeToMoveItExample
//
//  Created by Ryan Lintott on 2022-10-11.
//

import SwiftUI

@main
struct ILikeToMoveItExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        WindowGroup {
            BirdDetailView()            
        }
        .handlesExternalEvents(matching: [Bird.activityType])
    }
}
