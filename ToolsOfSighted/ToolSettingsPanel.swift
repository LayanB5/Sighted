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
    private func controls(for tool: ToolState.AdjustmentTool) -> some View {
        switch tool {
        case .simulatorControls:
            simulatorControls

        case .contrast:
            contrastControls

        case .borders:
            bordersControls

        case .symbols:
            symbolsControls
        }
    }

    private var simulatorControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 16) {
            if let selectedPerception = toolState.selectedPerception {
                switch selectedPerception {
                case .cvdLens:
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Color Blindness Simulation")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Picker("CVD Type", selection: $toolState.selectedCVDType) {
                            ForEach(ToolState.CVDType.allCases, id: \.self) { type in
                                Text(type.rawValue)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        intensitySlider(
                            title: "Simulation Intensity",
                            value: $toolState.cvdIntensity
                        )

                        Text("Use this to test whether status colors, charts, and warnings still make sense without relying on color alone.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                case .lowVision:
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Low Vision Simulation")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        intensitySlider(
                            title: "Vision Difficulty",
                            value: $toolState.lowVisionIntensity
                        )

                        Text("This combines reduced clarity, lower contrast, and peripheral difficulty so you can check if details stay readable.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                case .dyslexia:
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Dyslexia Simulation")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        intensitySlider(
                            title: "Letter Change Speed",
                            value: $toolState.dyslexiaIntensity
                        )

                        Text("This changes how quickly letters swap, move, grow, and shrink without changing the real colors of the interface.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                case .contrast:
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Low Contrast Simulation")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        intensitySlider(
                            title: "Contrast Difficulty",
                            value: $toolState.contrastIntensity
                        )
                    }

                case .blur:
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Blurred Vision Simulation")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        intensitySlider(
                            title: "Blur Amount",
                            value: $toolState.blurIntensity
                        )
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Choose a perception first", systemImage: "eye")
                        .font(.headline)

                    Text("Open the eye menu and select Color Blindness, Low Vision, or Dyslexia. Then use this control to tune the selected simulation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func intensitySlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)

                Spacer()

                Text("\(Int(value.wrappedValue * 100))%")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            Slider(value: value, in: 0...1)
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
    private var bordersControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 16) {
            Toggle("Strong Borders", isOn: $toolState.strongBordersEnabled)

            Text("Adds stronger outlines so meaning is not carried by color alone.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var symbolsControls: some View {
        @Bindable var toolState = toolState

        return VStack(alignment: .leading, spacing: 16) {
            Toggle("Use Symbols with Color", isOn: $toolState.symbolsEnabled)

            Text("Helps designers avoid relying only on color to communicate status or meaning.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ToolSettingsPanel()
        .environment(ToolState())
}
