//
//  ContentView.swift
//  ToolsOfSighted
//

import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            Divider()
                .opacity(0.25)

            explanation

            Button {
                Task { @MainActor in
                    let result = await openImmersiveSpace(id: "FingertipToolsSpace")

                    switch result {
                    case .opened:
                        dismiss()

                    case .userCancelled, .error:
                        break

                    @unknown default:
                        break
                    }
                }
            } label: {
                Label("Open Sighted Space", systemImage: "eye")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)

            Text("Choose Demo, Import, or Live from the Source bar inside the immersive space.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(width: 430)
        .glassBackgroundEffect()
        .onDisappear {
        }
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
            Label("Use Source to switch between Demo, Import, and Live.", systemImage: "rectangle.on.rectangle")
            Label("Use the eye menu to choose P, D, or T filters.", systemImage: "eye")
            Label("Use fingertip tools for Contrast and Lens controls.", systemImage: "hand.raised")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    ContentView()
}
