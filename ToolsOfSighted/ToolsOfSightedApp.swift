//
//  ToolsOfSightedApp.swift
//  ToolsOfSighted
//
//  Created by رغد الجريوي on 20/05/2026.
//

import SwiftUI

@main
struct ToolsOfSightedApp: App {
    @State private var toolState = ToolState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(toolState)
        }
        .defaultSize(width: 430, height: 360)

        ImmersiveSpace(id: "FingertipToolsSpace") {
            FingertipToolsImmersiveView()
                .environment(toolState)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
