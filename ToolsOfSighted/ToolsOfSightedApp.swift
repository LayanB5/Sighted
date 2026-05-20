//
//  ToolsOfSightedApp.swift
//  ToolsOfSighted
//
//  Created by رغد الجريوي on 20/05/2026.
//

import SwiftUI

@main
struct ToolsOfSightedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        ImmersiveSpace(id: "FingertipToolsSpace") {
            FingertipToolsImmersiveView()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
