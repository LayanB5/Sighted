import SwiftUI

enum VisionMode {
    case normal
    case cvdLens
    case practice
}

struct ContentView: View {
    @State private var currentMode: VisionMode = .normal
    @State private var lensOffset: CGSize = .zero
    @State private var showLens = true

    @State private var contrastLevel: Double = 0.0
    @State private var brightnessLevel: Double = 0.0
    @State private var useStrongBorders = false
    @State private var useSymbols = true
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isFingerToolsSpaceOpen = false

    private let sampleSize = CGSize(width: 520, height: 300)
    private let lensSize: CGFloat = 150

    var body: some View {
        VStack(spacing: 22) {
            header

            ZStack {
                designSample(mode: currentMode == .practice ? .practice : .normal)

                if showLens && currentMode == .cvdLens {
                    lensView
                        .offset(lensOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    lensOffset = limitedOffset(value.translation)
                                }
                        )
                }
            }
            .frame(width: sampleSize.width, height: sampleSize.height)
            .animation(.easeInOut(duration: 0.25), value: currentMode)
            .animation(.easeInOut(duration: 0.2), value: showLens)
            .animation(.easeInOut(duration: 0.2), value: contrastLevel)
            .animation(.easeInOut(duration: 0.2), value: brightnessLevel)

            statusPanel

            toolsBar

            if currentMode == .practice {
                designerControls
            }
        }
        .padding(40)
        .frame(width: 780)
        .glassBackgroundEffect()
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Sighted Tools")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Practice seeing, checking, and fixing color decisions.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func designSample(mode: VisionMode) -> some View {
        let colors = colorSet(for: mode)

        return ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                .shadow(radius: 18)

            VStack(spacing: 22) {
                HStack(spacing: 18) {
                    statusCard(
                        title: "Gate A",
                        subtitle: "Open",
                        color: colors.green,
                        symbol: "arrow.right",
                        mode: mode
                    )

                    statusCard(
                        title: "Gate B",
                        subtitle: "Closed",
                        color: colors.red,
                        symbol: "xmark",
                        mode: mode
                    )
                }

                HStack(spacing: 18) {
                    directionSign(
                        title: "Exit",
                        color: colors.blue,
                        symbol: "arrow.up.right",
                        mode: mode
                    )

                    directionSign(
                        title: "Warning",
                        color: colors.orange,
                        symbol: "exclamationmark.triangle.fill",
                        mode: mode
                    )
                }
            }
            .padding(28)
        }
        .frame(width: sampleSize.width, height: sampleSize.height)
    }

    private var lensView: some View {
        ZStack {
            designSample(mode: .cvdLens)
                .frame(width: sampleSize.width, height: sampleSize.height)
                .offset(x: -lensOffset.width, y: -lensOffset.height)
                .mask(
                    RoundedRectangle(cornerRadius: 34)
                        .frame(width: lensSize, height: lensSize)
                )

            RoundedRectangle(cornerRadius: 34)
                .strokeBorder(.white.opacity(0.9), lineWidth: 4)
                .frame(width: lensSize, height: lensSize)
                .shadow(color: .white.opacity(0.35), radius: 12)

            VStack(spacing: 4) {
                Image(systemName: "eye")
                    .font(.title3)
                Text("CVD Lens")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.black.opacity(0.45), in: Capsule())
            .offset(y: -(lensSize / 2) - 22)
        }
        .frame(width: lensSize, height: lensSize)
    }

    private func statusCard(title: String, subtitle: String, color: Color, symbol: String, mode: VisionMode) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(adjusted(color))
                .frame(width: 46, height: 46)
                .overlay {
                    if useSymbols || mode != .normal {
                        Image(systemName: symbol)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()
        }
        .padding(18)
        .frame(width: 220, height: 100)
        .background(adjusted(color).opacity(mode == .practice ? 0.48 : 0.38), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(adjusted(color).opacity(useStrongBorders || mode == .practice ? 1.0 : 0.9), lineWidth: useStrongBorders || mode == .practice ? 4 : 2)
        }
    }

    private func directionSign(title: String, color: Color, symbol: String, mode: VisionMode) -> some View {
        HStack(spacing: 12) {
            if useSymbols || mode != .normal {
                Image(systemName: symbol)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text(title)
                .font(.title3)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .padding(18)
        .frame(width: 220, height: 90)
        .background(adjusted(color), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(useStrongBorders || mode == .practice ? 0.85 : 0.0), lineWidth: useStrongBorders || mode == .practice ? 3 : 0)
        }
    }

    private var statusPanel: some View {
        HStack(spacing: 14) {
            Label(statusTitle, systemImage: statusIcon)
                .font(.headline)
                .foregroundStyle(statusColor)

            Text(statusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: Capsule())
    }

    private var toolsBar: some View {
        HStack(spacing: 14) {
            toolButton(title: "Normal", systemImage: "eye", mode: .normal)
            toolButton(title: "CVD Lens", systemImage: "circle.dashed", mode: .cvdLens)
            toolButton(title: "Practice", systemImage: "slider.horizontal.3", mode: .practice)

            Button {
                resetDesignerTools()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)

            Button {
                Task {
                    if isFingerToolsSpaceOpen {
                        await dismissImmersiveSpace()
                        isFingerToolsSpaceOpen = false
                    } else {
                        let result = await openImmersiveSpace(id: "FingertipToolsSpace")
                        
                        switch result {
                        case .opened:
                            isFingerToolsSpaceOpen = true
                        case .userCancelled, .error:
                            isFingerToolsSpaceOpen = false
                        @unknown default:
                            isFingerToolsSpaceOpen = false
                        }
                    }
                }
            } label: {
                Label(
                    isFingerToolsSpaceOpen ? "Hide Finger Tools" : "Finger Tools",
                    systemImage: isFingerToolsSpaceOpen ? "hand.raised.slash" : "hand.point.up.left.fill"
                )
                .font(.headline)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var designerControls: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Designer Tools", systemImage: "paintpalette")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Contrast")
                        .frame(width: 90, alignment: .leading)
                    Slider(value: $contrastLevel, in: 0...1)
                    Text("\(Int(contrastLevel * 100))%")
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                }

                HStack {
                    Text("Brightness")
                        .frame(width: 90, alignment: .leading)
                    Slider(value: $brightnessLevel, in: 0...1)
                    Text("\(Int(brightnessLevel * 100))%")
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                }

                Toggle("Strong borders", isOn: $useStrongBorders)
                Toggle("Use symbols, not color only", isOn: $useSymbols)
            }
        }
        .padding(18)
        .frame(maxWidth: 560)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private func toolButton(title: String, systemImage: String, mode: VisionMode) -> some View {
        Button {
            currentMode = mode
            if mode == .cvdLens {
                showLens = true
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(currentMode == mode ? .accentColor : .gray)
    }

    private func colorSet(for mode: VisionMode) -> (green: Color, red: Color, blue: Color, orange: Color) {
        switch mode {
        case .normal:
            return (
                green: .green,
                red: .red,
                blue: .blue,
                orange: .orange
            )
        case .cvdLens:
            return (
                green: Color(red: 0.56, green: 0.50, blue: 0.20),
                red: Color(red: 0.52, green: 0.45, blue: 0.18),
                blue: Color(red: 0.25, green: 0.38, blue: 0.58),
                orange: Color(red: 0.58, green: 0.50, blue: 0.22)
            )
        case .practice:
            return (
                green: Color(red: 0.0, green: 0.75, blue: 0.45),
                red: Color(red: 0.95, green: 0.18, blue: 0.22),
                blue: Color(red: 0.0, green: 0.45, blue: 1.0),
                orange: Color(red: 1.0, green: 0.62, blue: 0.0)
            )
        }
    }

    private func adjusted(_ color: Color) -> Color {
        return color
    }
    private var statusTitle: String {
        switch currentMode {
        case .normal:
            return "Original design"
        case .cvdLens:
            return "Potential issue"
        case .practice:
            return practiceIsPassing ? "Improving" : "Needs adjustment"
        }
    }

    private var statusDescription: String {
        switch currentMode {
        case .normal:
            return "Color is carrying important meaning."
        case .cvdLens:
            return "Some colors may become harder to distinguish."
        case .practice:
            return practiceIsPassing ? "Contrast, borders, and symbols improve clarity." : "Use the tools until the design becomes clearer."
        }
    }

    private var statusIcon: String {
        switch currentMode {
        case .normal:
            return "info.circle"
        case .cvdLens:
            return "exclamationmark.triangle"
        case .practice:
            return practiceIsPassing ? "checkmark.circle" : "slider.horizontal.3"
        }
    }

    private var statusColor: Color {
        switch currentMode {
        case .normal:
            return .secondary
        case .cvdLens:
            return .orange
        case .practice:
            return practiceIsPassing ? .green : .orange
        }
    }

    private var practiceIsPassing: Bool {
        contrastLevel > 0.55 && brightnessLevel > 0.25 && useStrongBorders && useSymbols
    }

    private func resetDesignerTools() {
        lensOffset = .zero
        showLens = true
        contrastLevel = 0.0
        brightnessLevel = 0.0
        useStrongBorders = false
        useSymbols = true
        currentMode = .normal
    }

    private func limitedOffset(_ translation: CGSize) -> CGSize {
        let maxX = (sampleSize.width - lensSize) / 2
        let maxY = (sampleSize.height - lensSize) / 2

        return CGSize(
            width: min(max(translation.width, -maxX), maxX),
            height: min(max(translation.height, -maxY), maxY)
        )
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
