//
//  ToolSettingsPanel.swift
//  ToolsOfSighted
//

import SwiftUI

struct ToolSettingsPanel: View {
    @Environment(ToolState.self) private var toolState

    var body: some View {
        @Bindable var toolState = toolState

        if let selectedTool = toolState.selectedTool {
            VStack(alignment: .leading, spacing: 18) {
                header(for: selectedTool)

                Divider()
                    .opacity(0.25)

                controls(for: selectedTool)
            }
            .padding(22)
            .frame(width: 390)
            .glassBackgroundEffect()
        }
    }

    private func header(for tool: SightTool) -> some View {
        @Bindable var toolState = toolState

        return HStack(spacing: 12) {
            Image(systemName: tool.iconName)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.rawValue)
                    .font(.headline)

                Text(tool.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: $toolState.isToolEnabled)
                .labelsHidden()
        }
    }

    @ViewBuilder
    private func controls(for tool: SightTool) -> some View {
        switch tool {
        case .cvdLens:
            cvdLensControls

        case .lowVision:
            lowVisionControls

        case .dyslexia:
            dyslexiaControls

        case .contrast:
            contrastControls

        case .blur:
            blurControls
        }
    }

    private var cvdLensControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 16) {
            Text("Color Blindness Type")
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker("CVD Type", selection: $toolState.selectedCVDType) {
                ForEach(ToolState.CVDType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Filter Intensity")

                    Spacer()

                    Text("\(Int(toolState.cvdIntensity * 100))%")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                Slider(value: $toolState.cvdIntensity, in: 0...1)
            }

            Text("This simulates how colors may appear for users with different types of color blindness.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var lowVisionControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Vision Clarity")

                    Spacer()

                    Text("\(Int(toolState.lowVisionIntensity * 100))%")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                Slider(value: $toolState.lowVisionIntensity, in: 0...1)
            }

            Text("Use this to preview reduced clarity and difficulty seeing small interface details.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var dyslexiaControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Reading Distortion")

                    Spacer()

                    Text("\(Int(toolState.dyslexiaIntensity * 100))%")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                Slider(value: $toolState.dyslexiaIntensity, in: 0...1)
            }

            Text("This simulates text instability and reading difficulty for accessibility testing.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var contrastControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Contrast Level")

                    Spacer()

                    Text("\(Int(toolState.contrastIntensity * 100))%")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                Slider(value: $toolState.contrastIntensity, in: 0...1)
            }

            Text("Use this to test whether interface elements remain visible with different contrast levels.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var blurControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Blur Amount")

                    Spacer()

                    Text("\(Int(toolState.blurIntensity * 100))%")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                Slider(value: $toolState.blurIntensity, in: 0...1)
            }

            Text("This simulates unclear or blurred vision.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ToolSettingsPanel()
        .environment(ToolState())
}
