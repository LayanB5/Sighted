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

        WindowGroup(id: "ToolSettingsWindow") {
            ToolSettingsPanel()
                .environment(toolState)
                .frame(minWidth: 420, minHeight: 360)
                .onDisappear {
                    toolState.selectedAdjustmentTool = nil
                    toolState.isToolEnabled = false
                }
        }
        .defaultSize(width: 460, height: 430)

        ImmersiveSpace(id: "FingertipToolsSpace") {
            FingertipToolsImmersiveView()
                .environment(toolState)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
