//
//  ContentView.swift
//  ToolsOfSighted
//

import SwiftUI

struct ContentView: View {
    @Environment(ToolState.self) private var toolState
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var immersiveSpaceIsOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            Divider()
                .opacity(0.25)

            explanation

            Button {
                Task {
                    if immersiveSpaceIsOpen {
                        await dismissImmersiveSpace()
                        immersiveSpaceIsOpen = false
                    } else {
                        let result = await openImmersiveSpace(id: "FingertipToolsSpace")

                        if case .opened = result {
                            immersiveSpaceIsOpen = true
                        }
                    }
                }
            } label: {
                Label(
                    immersiveSpaceIsOpen ? "Close Sighted Space" : "Open Sighted Space",
                    systemImage: immersiveSpaceIsOpen ? "xmark.circle" : "eye"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)

            Text("Perception modes and hand tools are controlled inside the immersive space.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(width: 430)
        .glassBackgroundEffect()
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text("Sighted")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Design beyond one perspective")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Choose a perception mode from the eye button.", systemImage: "eye")
            Label("Adjust tools from the hand controls.", systemImage: "hand.raised")
            Label("Preview your work through accessibility perspectives.", systemImage: "sparkles")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    ContentView()
        .environment(ToolState())
}
