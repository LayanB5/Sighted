//
//  ToolSettingsPanel.swift
//  ToolsOfSighted
//

import SwiftUI

struct ToolSettingsPanel: View {
    @Environment(ToolState.self) private var toolState

    var body: some View {
        @Bindable var toolState = toolState

        if let selectedTool = toolState.selectedAdjustmentTool {
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

    private func header(for tool: ToolState.AdjustmentTool) -> some View {
        @Bindable var toolState = toolState

        return HStack(spacing: 12) {
            Image(systemName: tool.iconName)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
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
    private func controls(for tool: ToolState.AdjustmentTool) -> some View {
        switch tool {
        case .simulatorControls, .contrast:
            contrastControls

        case .borders, .symbols:
            lensControls
        }
    }

    private var contrastControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 18) {
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

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Brightness")

                    Spacer()

                    Text("\(Int(toolState.brightnessIntensity * 100))%")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                Slider(value: $toolState.brightnessIntensity, in: 0...1)
            }

            Text("Use contrast and brightness together to test whether interface elements stay readable in different visual conditions.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    private var lensControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Inspection Lens")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Use Lens mode to inspect one focused area without changing the whole view.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle("Color blindness filter", isOn: lensToggleBinding)

            Picker("Mode", selection: $toolState.filterApplicationMode) {
                ForEach(ToolState.FilterApplicationMode.allCases, id: \.self) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Filter intensity")

                    Spacer()

                    Text("\(Int(toolState.cvdIntensity * 100))%")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                Slider(value: $toolState.cvdIntensity, in: 0...1)
            }
        }
    }

    private var lensToggleBinding: Binding<Bool> {
        Binding(
            get: {
                toolState.isPerceptionEnabled && toolState.selectedPerception == .cvdLens
            },
            set: { isEnabled in
                toolState.isPerceptionEnabled = isEnabled
                if isEnabled {
                    toolState.selectedPerception = .cvdLens
                }
            }
        )
    }
}

#Preview {
    ToolSettingsPanel()
        .environment(ToolState())
}
