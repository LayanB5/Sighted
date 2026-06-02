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
    @State private var designReviewState = DesignReviewState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(toolState)
                .environment(designReviewState)
        }
        .defaultSize(width: 430, height: 360)

        ImmersiveSpace(id: "FingertipToolsSpace") {
            FingertipToolsView()
                .environment(toolState)
                .environment(designReviewState)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
