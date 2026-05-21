import SwiftUI
import RealityKit
import RealityKitContent

struct FingertipToolsImmersiveView: View {
    @Environment(ToolState.self) private var toolState
    @State private var handTrackingModel = HandTrackingModel()
    @State private var selectedToolID: String?
    @State private var settingsPanelPosition: SIMD3<Float> = [0.28, 1.25, -0.85]
    @State private var panelDragStartPosition: SIMD3<Float> = [0.28, 1.25, -0.85]
    @State private var isTestingWithoutHands = true
    @State private var filterOverlayPosition: SIMD3<Float> = [0.0, 1.18, -2.2]

    var body: some View {
        RealityView { content, attachments in
            for tool in handTrackingModel.tools {
                if let toolEntity = attachments.entity(for: tool.attachmentID) {
                    toolEntity.name = tool.attachmentID
                    toolEntity.position = tool.position
                    toolEntity.isEnabled = !isTestingWithoutHands && tool.isVisible
                    content.add(toolEntity)
                }
            }

            if let settingsPanel = attachments.entity(for: "ToolSettingsPanel") {
                settingsPanel.name = "ToolSettingsPanel"
                settingsPanel.position = settingsPanelPosition
                settingsPanel.isEnabled = selectedToolID != nil
                content.add(settingsPanel)
            }

            if let handToolsMenu = attachments.entity(for: "HandToolsTestMenu") {
                handToolsMenu.name = "HandToolsTestMenu"
                handToolsMenu.position = [0.48, 1.02, -0.76]
                handToolsMenu.isEnabled = isTestingWithoutHands
                content.add(handToolsMenu)
            }

            if let perceptionEyeMenu = attachments.entity(for: "PerceptionEyeMenu") {
                perceptionEyeMenu.name = "PerceptionEyeMenu"
                perceptionEyeMenu.position = [-0.48, 1.02, -0.76]
                perceptionEyeMenu.isEnabled = true
                content.add(perceptionEyeMenu)
            }

            if let sampleDesign = attachments.entity(for: "SampleDesignCanvas") {
                sampleDesign.name = "SampleDesignCanvas"
                sampleDesign.position = [0.0, 1.08, -0.95]
                sampleDesign.isEnabled = true
                content.add(sampleDesign)
            }

            if let filterOverlay = attachments.entity(for: "FullSceneFilterOverlay") {
                filterOverlay.name = "FullSceneFilterOverlay"
                filterOverlay.position = filterOverlayPosition
                filterOverlay.scale = [4.8, 4.8, 1.0]
                filterOverlay.isEnabled = toolState.selectedPerception != nil && toolState.isPerceptionEnabled
                content.add(filterOverlay)
            }

            if let adjustmentOverlay = attachments.entity(for: "AdjustmentToolsOverlay") {
                adjustmentOverlay.name = "AdjustmentToolsOverlay"
                adjustmentOverlay.position = filterOverlayPosition
                adjustmentOverlay.scale = [4.8, 4.8, 1.0]
                adjustmentOverlay.isEnabled = toolState.isToolEnabled && toolState.selectedAdjustmentTool != nil
                content.add(adjustmentOverlay)
            }
        } update: { content, attachments in
            for tool in handTrackingModel.tools {
                if let toolEntity = attachments.entity(for: tool.attachmentID) {
                    if toolEntity.parent == nil {
                        content.add(toolEntity)
                    }

                    toolEntity.position = tool.position
                    toolEntity.isEnabled = !isTestingWithoutHands && tool.isVisible
                }
            }

            if let settingsPanel = attachments.entity(for: "ToolSettingsPanel") {
                if settingsPanel.parent == nil {
                    content.add(settingsPanel)
                }

                settingsPanel.position = settingsPanelPosition
                settingsPanel.isEnabled = selectedToolID != nil
            }

            if let handToolsMenu = attachments.entity(for: "HandToolsTestMenu") {
                if handToolsMenu.parent == nil {
                    content.add(handToolsMenu)
                }

                handToolsMenu.position = [0.48, 1.02, -0.76]
                handToolsMenu.isEnabled = isTestingWithoutHands
            }

            if let perceptionEyeMenu = attachments.entity(for: "PerceptionEyeMenu") {
                if perceptionEyeMenu.parent == nil {
                    content.add(perceptionEyeMenu)
                }

                perceptionEyeMenu.position = [-0.48, 1.02, -0.76]
                perceptionEyeMenu.isEnabled = true
            }

            if let sampleDesign = attachments.entity(for: "SampleDesignCanvas") {
                if sampleDesign.parent == nil {
                    content.add(sampleDesign)
                }

                sampleDesign.position = [0.0, 1.08, -0.95]
                sampleDesign.isEnabled = true
            }

            if let filterOverlay = attachments.entity(for: "FullSceneFilterOverlay") {
                if filterOverlay.parent == nil {
                    content.add(filterOverlay)
                }

                filterOverlay.position = filterOverlayPosition
                filterOverlay.scale = [4.8, 4.8, 1.0]
                filterOverlay.isEnabled = toolState.selectedPerception != nil && toolState.isPerceptionEnabled
            }

            if let adjustmentOverlay = attachments.entity(for: "AdjustmentToolsOverlay") {
                if adjustmentOverlay.parent == nil {
                    content.add(adjustmentOverlay)
                }

                adjustmentOverlay.position = filterOverlayPosition
                adjustmentOverlay.scale = [4.8, 4.8, 1.0]
                adjustmentOverlay.isEnabled = toolState.isToolEnabled && toolState.selectedAdjustmentTool != nil
            }
        } attachments: {
            ForEach(handTrackingModel.tools) { tool in
                Attachment(id: tool.attachmentID) {
                    FingertipToolButton(
                        tool: tool,
                        isSelected: selectedToolID == tool.id
                    ) {
                        selectedToolID = tool.id
                        toolState.selectedTool = sightTool(for: tool)
                        settingsPanelPosition = panelPosition(near: tool.position)
                        panelDragStartPosition = settingsPanelPosition
                        print("Selected tool: \(tool.title)")
                    }
                }
            }

            Attachment(id: "ToolSettingsPanel") {
                DraggableToolSettingsPanel(
                    panelPosition: $settingsPanelPosition,
                    panelDragStartPosition: $panelDragStartPosition
                )
            }

            Attachment(id: "HandToolsTestMenu") {
                HandToolsTestMenu(
                    selectedToolID: $selectedToolID,
                    settingsPanelPosition: $settingsPanelPosition,
                    panelDragStartPosition: $panelDragStartPosition
                )
            }

            Attachment(id: "PerceptionEyeMenu") {
                PerceptionEyeMenu()
            }

            Attachment(id: "SampleDesignCanvas") {
                SampleDesignCanvas()
            }

            Attachment(id: "FullSceneFilterOverlay") {
                FullSceneFilterOverlay()
            }

            Attachment(id: "AdjustmentToolsOverlay") {
                AdjustmentToolsOverlay()
            }
        }
        .task {
            await handTrackingModel.startTracking()
        }
        
    }

    private func panelPosition(near fingertipPosition: SIMD3<Float>) -> SIMD3<Float> {
        let horizontalOffset: Float = fingertipPosition.x < 0 ? 0.32 : -0.32
        let verticalOffset: Float = 0.04
        let depthOffset: Float = -0.04

        return [
            fingertipPosition.x + horizontalOffset,
            fingertipPosition.y + verticalOffset,
            fingertipPosition.z + depthOffset
        ]
    }

    private func sightTool(for fingertipTool: HandTrackingModel.FingertipTool) -> SightTool {
        let title = fingertipTool.title.lowercased()

        if title.contains("cvd") || title.contains("color") {
            return .cvdLens
        } else if title.contains("low") || title.contains("vision") {
            return .lowVision
        } else if title.contains("dyslexia") || title.contains("text") {
            return .dyslexia
        } else if title.contains("contrast") {
            return .contrast
        } else if title.contains("blur") {
            return .blur
        } else {
            return .cvdLens
        }
    }
}

private struct HandToolsTestMenu: View {
    @Environment(ToolState.self) private var toolState
    @Binding var selectedToolID: String?
    @Binding var settingsPanelPosition: SIMD3<Float>
    @Binding var panelDragStartPosition: SIMD3<Float>

    @State private var isExpanded = false

    var body: some View {
        @Bindable var toolState = toolState

        VStack(spacing: 12) {
            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(ToolState.AdjustmentTool.allCases) { tool in
                        Button {
                            select(tool)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: tool.iconName)
                                    .font(.headline)
                                    .frame(width: 30, height: 30)
                                    .background(.white.opacity(isSelected(tool) ? 0.24 : 0.10))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tool.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)

                                    Text(tool.shortDescription)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if isSelected(tool) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(width: 240)
                            .background(.white.opacity(isSelected(tool) ? 0.15 : 0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.92, anchor: .top)))
            }

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "hand.raised.fill")
                        .font(.headline)

                    Text("Tools")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .opacity(0.75)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.white.opacity(0.16), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(isExpanded ? 0.70 : 0.30), lineWidth: isExpanded ? 1.4 : 1.0)
                }
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.06))
                .glassBackgroundEffect()
        }
    }

    private func isSelected(_ tool: ToolState.AdjustmentTool) -> Bool {
        selectedToolID == "adjustment-\(tool.rawValue)" && toolState.selectedAdjustmentTool == tool
    }

    private func select(_ tool: ToolState.AdjustmentTool) {
        selectedToolID = "adjustment-\(tool.rawValue)"
        toolState.selectedAdjustmentTool = tool
        toolState.isToolEnabled = true

        settingsPanelPosition = [0.32, 1.25, -0.72]
        panelDragStartPosition = settingsPanelPosition
    }
}

private struct SampleDesignCanvas: View {
    @Environment(ToolState.self) private var toolState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            HStack(spacing: 16) {
                statusCard(
                    title: "Approved",
                    subtitle: "Color + symbol",
                    color: perceivedColor(.green),
                    symbol: "checkmark.circle.fill"
                )

                statusCard(
                    title: "Warning",
                    subtitle: "Needs attention",
                    color: perceivedColor(.orange),
                    symbol: "exclamationmark.triangle.fill"
                )

                statusCard(
                    title: "Error",
                    subtitle: "Action required",
                    color: perceivedColor(.red),
                    symbol: "xmark.circle.fill"
                )
            }

            HStack(spacing: 18) {
                chartPreview
                formPreview
            }
        }
        .padding(26)
        .frame(width: 760)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(toolState.strongBordersEnabled ? 0.55 : 0.18), lineWidth: toolState.strongBordersEnabled ? 3 : 1)
        }
        .brightness(perceptionBrightness + (toolState.isToolEnabled ? (toolState.brightnessIntensity - 0.30) * 0.45 : 0))
        .contrast(perceptionContrast * (toolState.isToolEnabled ? (0.75 + toolState.contrastIntensity * 1.15) : 1))
        .saturation(perceptionSaturation)
        .blur(radius: perceptionBlurRadius)
        .opacity(perceptionOpacity)
        .overlay {
            perceptionOverlay
        }
        .glassBackgroundEffect()
    }

    private enum SemanticColor {
        case blue
        case green
        case orange
        case red
    }

    private func perceivedColor(_ color: SemanticColor) -> Color {
        guard toolState.isPerceptionEnabled,
              toolState.selectedPerception == .cvdLens else {
            return normalColor(color)
        }

        switch toolState.selectedCVDType {
        case .protanopia:
            return protanopiaColor(color)
        case .deuteranopia:
            return deuteranopiaColor(color)
        case .tritanopia:
            return tritanopiaColor(color)
        }
    }

    private func normalColor(_ color: SemanticColor) -> Color {
        switch color {
        case .blue:
            return .blue
        case .green:
            return .green
        case .orange:
            return .orange
        case .red:
            return .red
        }
    }

    private func protanopiaColor(_ color: SemanticColor) -> Color {
        switch color {
        case .blue:
            return Color(red: 0.20, green: 0.40, blue: 0.74)
        case .green:
            return Color(red: 0.66, green: 0.61, blue: 0.28)
        case .orange:
            return Color(red: 0.69, green: 0.58, blue: 0.24)
        case .red:
            return Color(red: 0.50, green: 0.45, blue: 0.23)
        }
    }

    private func deuteranopiaColor(_ color: SemanticColor) -> Color {
        switch color {
        case .blue:
            return Color(red: 0.18, green: 0.42, blue: 0.74)
        case .green:
            return Color(red: 0.67, green: 0.58, blue: 0.26)
        case .orange:
            return Color(red: 0.72, green: 0.57, blue: 0.23)
        case .red:
            return Color(red: 0.62, green: 0.52, blue: 0.24)
        }
    }

    private func tritanopiaColor(_ color: SemanticColor) -> Color {
        switch color {
        case .blue:
            return Color(red: 0.22, green: 0.56, blue: 0.58)
        case .green:
            return Color(red: 0.26, green: 0.64, blue: 0.60)
        case .orange:
            return Color(red: 0.90, green: 0.48, blue: 0.44)
        case .red:
            return Color(red: 0.86, green: 0.36, blue: 0.44)
        }
    }

    private var perceptionBrightness: Double {
        guard toolState.isPerceptionEnabled, let perception = toolState.selectedPerception else {
            return 0
        }

        switch perception {
        case .lowVision:
            return -0.04 - toolState.lowVisionIntensity * 0.18
        case .contrast:
            return -0.10 - toolState.contrastIntensity * 0.16
        case .blur:
            return -0.03 - toolState.blurIntensity * 0.10
        case .dyslexia:
            return 0
        case .cvdLens:
            return 0
        }
    }

    private var perceptionContrast: Double {
        guard toolState.isPerceptionEnabled, let perception = toolState.selectedPerception else {
            return 1.0
        }

        switch perception {
        case .lowVision:
            return 0.72 - toolState.lowVisionIntensity * 0.18
        case .contrast:
            return 0.42 + toolState.contrastIntensity * 0.28
        case .blur:
            return 0.86 - toolState.blurIntensity * 0.18
        case .dyslexia:
            return 1.0
        case .cvdLens:
            return 1.0
        }
    }

    private var perceptionOpacity: Double {
        guard toolState.isPerceptionEnabled, let perception = toolState.selectedPerception else {
            return 1.0
        }

        switch perception {
        case .lowVision:
            return 1.0 - toolState.lowVisionIntensity * 0.10
        case .blur:
            return 1.0 - toolState.blurIntensity * 0.08
        default:
            return 1.0
        }
    }

    private var perceptionSaturation: Double {
        guard toolState.isPerceptionEnabled, let perception = toolState.selectedPerception else {
            return 1.0
        }

        switch perception {
        case .cvdLens:
            return 1.0 - toolState.cvdIntensity * 0.40
        case .lowVision:
            return 0.82 - toolState.lowVisionIntensity * 0.32
        case .dyslexia:
            return 1.0
        case .contrast:
            return 0.42
        case .blur:
            return 0.86 - toolState.blurIntensity * 0.36
        }
    }

    private var perceptionBlurRadius: CGFloat {
        guard toolState.isPerceptionEnabled, let perception = toolState.selectedPerception else {
            return 0
        }

        switch perception {
        case .lowVision:
            return CGFloat(toolState.lowVisionIntensity * 3.5)
        case .blur:
            return CGFloat(toolState.blurIntensity * 8.0)
        default:
            return 0
        }
    }

    @ViewBuilder
    private var perceptionOverlay: some View {
        if toolState.isPerceptionEnabled, let perception = toolState.selectedPerception {
            switch perception {
            case .cvdLens:
                cvdSampleOverlay

            case .lowVision:
                lowVisionSampleOverlay

            case .dyslexia:
                dyslexiaSampleOverlay

            case .contrast:
                ZStack {
                    Rectangle()
                        .fill(.black.opacity(0.30 + toolState.contrastIntensity * 0.34))
                        .blendMode(.multiply)

                    Rectangle()
                        .fill(.gray.opacity(0.18 + toolState.contrastIntensity * 0.28))
                        .blendMode(.saturation)
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            case .blur:
                ZStack {
                    Rectangle()
                        .fill(.white.opacity(0.12 + toolState.blurIntensity * 0.28))

                    Rectangle()
                        .fill(.gray.opacity(0.08 + toolState.blurIntensity * 0.18))
                        .blendMode(.saturation)
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
        }
    }

    private var cvdSampleOverlay: some View {
        ZStack {
            Rectangle()
                .fill(cvdTintColor)
                .opacity(0.08 + toolState.cvdIntensity * 0.18)
                .blendMode(.softLight)

            Rectangle()
                .fill(.gray.opacity(0.04 + toolState.cvdIntensity * 0.10))
                .blendMode(.saturation)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var cvdTintColor: Color {
        switch toolState.selectedCVDType {
        case .protanopia:
            return Color(red: 0.78, green: 0.66, blue: 0.32)
        case .deuteranopia:
            return Color(red: 0.70, green: 0.64, blue: 0.30)
        case .tritanopia:
            return Color(red: 0.40, green: 0.56, blue: 0.74)
        }
    }

    private var lowVisionSampleOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.white.opacity(0.18 + toolState.lowVisionIntensity * 0.42))
                .blendMode(.screen)

            Rectangle()
                .fill(.black.opacity(0.06 + toolState.lowVisionIntensity * 0.18))
                .blendMode(.multiply)

            RadialGradient(
                colors: [
                    .clear,
                    .black.opacity(0.12 + toolState.lowVisionIntensity * 0.22),
                    .black.opacity(0.28 + toolState.lowVisionIntensity * 0.52)
                ],
                center: .center,
                startRadius: 90,
                endRadius: 540
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var dyslexiaSampleOverlay: some View {
        Rectangle()
            .fill(.clear)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var isDyslexiaActive: Bool {
        toolState.isPerceptionEnabled && toolState.selectedPerception == .dyslexia
    }

    private var dyslexiaTextOffset: CGFloat {
        isDyslexiaActive ? CGFloat(3.0 + toolState.dyslexiaIntensity * 8.0) : 0
    }

    private func displayText(_ text: String) -> String {
        guard isDyslexiaActive else {
            return text
        }

        switch text {
        case "Sample Accessibility Test":
            return "Sampel Acessibiltiy Tset"
        case "Temporary design surface for checking color, contrast, borders, and symbols.":
            return "Temproary desgin suface for chekcing colro, conrtast, broders, and sybmols."
        case "Approved":
            return "Aproevd"
        case "Color + symbol":
            return "Colro + sybmol"
        case "Warning":
            return "Wranign"
        case "Needs attention":
            return "Nedes attnetion"
        case "Error":
            return "Erorr"
        case "Action required":
            return "Actoin requried"
        case "Color-coded chart":
            return "Colro-coded chrat"
        case "Form readability":
            return "From raedabiltiy"
        case "Primary action":
            return "Priamry atcion"
        case "Success message":
            return "Sucess mesage"
        case "Error message":
            return "Erorr mesage"
        default:
            return text
        }
    }

    private func dyslexiaReadableText(
        _ text: String,
        font: Font,
        weight: Font.Weight,
        secondary: Bool = false
    ) -> some View {
        DyslexiaAnimatedText(
            text: text,
            isActive: isDyslexiaActive,
            speed: toolState.dyslexiaIntensity,
            font: font,
            weight: weight,
            secondary: secondary
        )
    }

private struct DyslexiaAnimatedText: View {
    let text: String
    let isActive: Bool
    let speed: Double
    let font: Font
    let weight: Font.Weight
    let secondary: Bool

    var body: some View {
        if isActive {
            TimelineView(.animation(minimumInterval: 0.045)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let tick = Int(time * changeRate)
                let scrambled = scrambledText(tick: tick)
                let characters = Array(scrambled.enumerated())

                ZStack(alignment: .leading) {
                    Text(scrambled)
                        .font(font)
                        .fontWeight(weight)
                        .foregroundStyle(secondary ? .secondary : .primary)
                        .opacity(0.20)
                        .offset(
                            x: CGFloat(randomValue(seed: tick + 91, min: -5.0, max: 2.0)),
                            y: CGFloat(randomValue(seed: tick + 37, min: -2.2, max: 1.8))
                        )
                        .blur(radius: 1.15)

                    HStack(spacing: 0) {
                        ForEach(characters, id: \.offset) { index, character in
                            animatedCharacter(
                                character,
                                index: index,
                                tick: tick
                            )
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.055), value: tick)
            }
        } else {
            Text(text)
                .font(font)
                .fontWeight(weight)
                .foregroundStyle(secondary ? .secondary : .primary)
        }
    }

    private var changeRate: Double {
        4.0 + speed * 12.0
    }

    private func animatedCharacter(_ character: Character, index: Int, tick: Int) -> some View {
        let seed = tick * 97 + index * 31 + text.count * 13
        let x = randomValue(seed: seed + 1, min: -3.8, max: 3.8) * (0.35 + speed)
        let y = randomValue(seed: seed + 2, min: -3.2, max: 3.2) * (0.30 + speed)
        let scale = randomValue(seed: seed + 3, min: 0.84, max: 1.22 + speed * 0.12)
        let rotation = randomValue(seed: seed + 4, min: -4.0, max: 4.0) * (0.4 + speed)
        let opacity = randomValue(seed: seed + 5, min: 0.78, max: 1.0)
        let extraKerning = randomValue(seed: seed + 6, min: 0.2, max: 2.4) * (0.35 + speed)

        return Text(String(character))
            .font(font)
            .fontWeight(weight)
            .foregroundStyle(secondary ? .secondary : .primary)
            .opacity(opacity)
            .scaleEffect(CGFloat(scale))
            .rotationEffect(.degrees(rotation))
            .offset(x: CGFloat(x), y: CGFloat(y))
            .kerning(extraKerning)
    }

    private func scrambledText(tick: Int) -> String {
        text.split(separator: " ", omittingEmptySubsequences: false)
            .enumerated()
            .map { wordIndex, wordSubsequence in
                scrambledWord(String(wordSubsequence), seed: tick + wordIndex * 17)
            }
            .joined(separator: " ")
    }

    private func scrambledWord(_ word: String, seed: Int) -> String {
        var characters = Array(word)

        guard characters.count > 3 else {
            return word
        }

        let innerStart = 1
        let innerEnd = characters.count - 2
        let swapCount = 1 + Int(speed * 3.0)

        for swapIndex in 0..<swapCount {
            let first = innerStart + positiveModulo(seed * (swapIndex + 3) + characters.count, innerEnd)
            let second = innerStart + positiveModulo(seed * (swapIndex + 7) + characters.count * 2, innerEnd)

            if first < characters.count - 1,
               second < characters.count - 1,
               first != second {
                characters.swapAt(first, second)
            }
        }

        return String(characters)
    }

    private func positiveModulo(_ value: Int, _ upperBound: Int) -> Int {
        guard upperBound > 0 else {
            return 0
        }

        let result = value % upperBound
        return result >= 0 ? result : result + upperBound
    }

    private func randomValue(seed: Int, min: Double, max: Double) -> Double {
        let raw = abs(sin(Double(seed) * 12.9898 + 78.233) * 43758.5453)
        let fraction = raw - floor(raw)
        return min + fraction * (max - min)
    }
}

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                dyslexiaReadableText("Sample Accessibility Test", font: .title2, weight: .bold)

                dyslexiaReadableText(
                    "Temporary design surface for checking color, contrast, borders, and symbols.",
                    font: .caption,
                    weight: .regular,
                    secondary: true
                )
            }

            Spacer()

            Label("Demo", systemImage: "sparkles")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white.opacity(0.10), in: Capsule())
        }
    }

    private func statusCard(title: String, subtitle: String, color: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)

                if toolState.symbolsEnabled {
                    Image(systemName: symbol)
                        .foregroundStyle(color)
                        .font(.headline)
                }

                Spacer()
            }

            dyslexiaReadableText(title, font: .headline, weight: .semibold)
                .offset(x: dyslexiaTextOffset)

            dyslexiaReadableText(subtitle, font: .caption, weight: .regular, secondary: true)
                .offset(x: -dyslexiaTextOffset * 0.6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 125, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(toolState.strongBordersEnabled ? 0.55 : 0.12), lineWidth: toolState.strongBordersEnabled ? 2.5 : 1)
        }
    }

    private var chartPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            dyslexiaReadableText("Color-coded chart", font: .headline, weight: .semibold)
                .offset(x: dyslexiaTextOffset)

            HStack(alignment: .bottom, spacing: 12) {
                chartBar(height: 95, color: perceivedColor(.blue), label: "A")
                chartBar(height: 135, color: perceivedColor(.green), label: "B")
                chartBar(height: 75, color: perceivedColor(.orange), label: "C")
                chartBar(height: 115, color: perceivedColor(.red), label: "D")
            }
            .frame(height: 155, alignment: .bottom)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(toolState.strongBordersEnabled ? 0.50 : 0.12), lineWidth: toolState.strongBordersEnabled ? 2.5 : 1)
        }
    }

    private func chartBar(height: CGFloat, color: Color, label: String) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 42, height: height)
                .overlay {
                    if toolState.symbolsEnabled {
                        Text(label)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var formPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            dyslexiaReadableText("Form readability", font: .headline, weight: .semibold)
                .offset(x: dyslexiaTextOffset)

            VStack(alignment: .leading, spacing: 10) {
                fieldRow(title: "Primary action", color: perceivedColor(.blue), icon: "arrow.right.circle.fill")
                fieldRow(title: "Success message", color: perceivedColor(.green), icon: "checkmark.circle.fill")
                fieldRow(title: "Error message", color: perceivedColor(.red), icon: "xmark.octagon.fill")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(toolState.strongBordersEnabled ? 0.50 : 0.12), lineWidth: toolState.strongBordersEnabled ? 2.5 : 1)
        }
    }

    private func fieldRow(title: String, color: Color, icon: String) -> some View {
        HStack(spacing: 10) {
            if toolState.symbolsEnabled {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            dyslexiaReadableText(title, font: .subheadline, weight: .semibold)
                .offset(x: dyslexiaTextOffset)

            Spacer()

            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 42, height: 14)
        }
        .padding(12)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(toolState.strongBordersEnabled ? 0.45 : 0.10), lineWidth: toolState.strongBordersEnabled ? 2 : 1)
        }
    }
}

private struct FullSceneFilterOverlay: View {
    @Environment(ToolState.self) private var toolState

    var body: some View {
        if let selectedPerception = toolState.selectedPerception {
            ZStack {
                Rectangle()
                    .fill(overlayColor(for: selectedPerception))
                    .opacity(overlayOpacity(for: selectedPerception))
                    .ignoresSafeArea()

                if selectedPerception == .cvdLens {
                    cvdDesaturationLayer
                    cvdColorCompressionLayer
                }

                if selectedPerception == .lowVision {
                    lowVisionHazeLayer
                    lowVisionVignetteLayer
                    lowVisionFocusLossLayer
                }

                if selectedPerception == .blur {
                    frostedLayer(for: selectedPerception)
                }

                if selectedPerception == .dyslexia {
                    dyslexiaDistortionLayer
                }
            }
            .frame(width: 4200, height: 2800)
            .contentShape(Rectangle())
            .allowsHitTesting(false)
        }
    }

    private func overlayColor(for perception: SightTool) -> Color {
        switch perception {
        case .cvdLens:
            switch toolState.selectedCVDType {
            case .protanopia:
                return Color(red: 0.72, green: 0.62, blue: 0.34)
            case .deuteranopia:
                return Color(red: 0.68, green: 0.62, blue: 0.32)
            case .tritanopia:
                return Color(red: 0.42, green: 0.56, blue: 0.72)
            }

        case .lowVision:
            return .white

        case .dyslexia:
            return .clear

        case .contrast:
            return .black

        case .blur:
            return .white
        }
    }

    private func overlayOpacity(for perception: SightTool) -> Double {
        switch perception {
        case .cvdLens:
            return 0.16 + toolState.cvdIntensity * 0.50

        case .lowVision:
            return 0.10 + toolState.lowVisionIntensity * 0.34

        case .dyslexia:
            return 0.0

        case .contrast:
            return 0.06 + toolState.contrastIntensity * 0.44

        case .blur:
            return 0.14 + toolState.blurIntensity * 0.56
        }
    }

    private var cvdDesaturationLayer: some View {
        let intensity = toolState.cvdIntensity

        return Rectangle()
            .fill(.gray.opacity(0.10 + intensity * 0.32))
            .blendMode(.saturation)
            .opacity(0.35 + intensity * 0.45)
    }

    private var cvdColorCompressionLayer: some View {
        let intensity = toolState.cvdIntensity

        return ZStack {
            switch toolState.selectedCVDType {
            case .protanopia:
                Rectangle()
                    .fill(Color(red: 0.58, green: 0.48, blue: 0.20).opacity(0.05 + intensity * 0.16))
                    .blendMode(.multiply)

            case .deuteranopia:
                Rectangle()
                    .fill(Color(red: 0.52, green: 0.50, blue: 0.22).opacity(0.05 + intensity * 0.18))
                    .blendMode(.multiply)

            case .tritanopia:
                Rectangle()
                    .fill(Color(red: 0.30, green: 0.46, blue: 0.62).opacity(0.04 + intensity * 0.16))
                    .blendMode(.multiply)
            }
        }
    }

    private var lowVisionHazeLayer: some View {
        let intensity = toolState.lowVisionIntensity

        return ZStack {
            Rectangle()
                .fill(.regularMaterial)
                .opacity(0.20 + intensity * 0.45)

            Rectangle()
                .fill(.white.opacity(0.08 + intensity * 0.24))
        }
    }

    private var lowVisionVignetteLayer: some View {
        let intensity = toolState.lowVisionIntensity

        return RadialGradient(
            colors: [
                .clear,
                .clear,
                .black.opacity(0.10 + intensity * 0.50)
            ],
            center: .center,
            startRadius: 180,
            endRadius: 1200
        )
        .opacity(0.55 + intensity * 0.35)
    }

    private var lowVisionFocusLossLayer: some View {
        let intensity = toolState.lowVisionIntensity

        return ZStack {
            ForEach(0..<9, id: \.self) { index in
                Circle()
                    .stroke(.white.opacity(0.04 + intensity * 0.10), lineWidth: 2 + intensity * 4)
                    .frame(width: CGFloat(260 + index * 180), height: CGFloat(260 + index * 180))
                    .blur(radius: 2 + intensity * 10)
                    .opacity(index.isMultiple(of: 2) ? 0.35 : 0.22)
            }
        }
        .blendMode(.screen)
    }

    private func frostedLayer(for perception: SightTool) -> some View {
        let strength = perception == .blur ? toolState.blurIntensity : toolState.lowVisionIntensity

        return ZStack {
            Rectangle()
                .fill(.regularMaterial)
                .opacity(0.30 + strength * 0.58)

            Rectangle()
                .fill(.white.opacity(0.04 + strength * 0.18))
        }
    }

    private var dyslexiaDistortionLayer: some View {
        EmptyView()
    }
}


private struct AdjustmentToolsOverlay: View {
    @Environment(ToolState.self) private var toolState

    var body: some View {
        ZStack {
            brightnessLayer
            contrastLayer

            if toolState.strongBordersEnabled {
                strongBordersLayer
            }

            if toolState.symbolsEnabled {
                symbolsSupportLayer
            }
        }
        .frame(width: 4200, height: 2800)
        .contentShape(Rectangle())
        .allowsHitTesting(false)
    }

    private var brightnessLayer: some View {
        let value = toolState.brightnessIntensity
        let opacity = abs(value - 0.30) * 0.75

        return Rectangle()
            .fill(value >= 0.30 ? .white : .black)
            .opacity(opacity)
            .blendMode(value >= 0.30 ? .screen : .multiply)
    }

    private var contrastLayer: some View {
        let value = toolState.contrastIntensity

        return ZStack {
            Rectangle()
                .fill(.black.opacity(max(0, value - 0.50) * 0.48))
                .blendMode(.multiply)

            Rectangle()
                .fill(.white.opacity(max(0, value - 0.50) * 0.22))
                .blendMode(.screen)

            Rectangle()
                .fill(.gray.opacity(max(0, 0.50 - value) * 0.55))
                .blendMode(.saturation)
        }
    }

    private var strongBordersLayer: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 42, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 8)
                    .frame(
                        width: CGFloat(900 + index * 360),
                        height: CGFloat(560 + index * 230)
                    )
                    .opacity(index.isMultiple(of: 2) ? 0.40 : 0.24)
            }

            Rectangle()
                .strokeBorder(.white.opacity(0.16), lineWidth: 12)
        }
        .blendMode(.screen)
    }

    private var symbolsSupportLayer: some View {
        VStack {
            HStack(spacing: 34) {
                symbolBadge(systemImage: "checkmark.circle.fill", label: "Clear status")
                symbolBadge(systemImage: "exclamationmark.triangle.fill", label: "Warning")
                symbolBadge(systemImage: "xmark.circle.fill", label: "Error")
            }

            Spacer()
        }
        .padding(.top, 360)
        .opacity(0.42)
    }

    private func symbolBadge(systemImage: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .semibold))

            Text(label)
                .font(.system(size: 28, weight: .semibold))
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.black.opacity(0.24), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.20), lineWidth: 2)
        }
    }
}

struct FingertipToolButton: View {
    let tool: HandTrackingModel.FingertipTool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tool.systemImage)
                    .font(.system(size: 18, weight: .semibold))

                Text(tool.title)
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)
            .frame(width: isSelected ? 62 : 52, height: isSelected ? 62 : 52)
            .background(
                Circle()
                    .fill(isSelected ? Color.blue.opacity(0.85) : Color.white.opacity(0.18))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isSelected ? 1.0 : 0.85), lineWidth: isSelected ? 2.4 : 1.4)
            )
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
            .glassBackgroundEffect()
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }
}

private struct DraggableToolSettingsPanel: View {
    @Binding var panelPosition: SIMD3<Float>
    @Binding var panelDragStartPosition: SIMD3<Float>

    var body: some View {
        ToolSettingsPanel()
            .overlay(alignment: .topTrailing) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(10)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let scale: Float = 0.0012
                        panelPosition = [
                            panelDragStartPosition.x + Float(value.translation.width) * scale,
                            panelDragStartPosition.y - Float(value.translation.height) * scale,
                            panelDragStartPosition.z
                        ]
                    }
                    .onEnded { _ in
                        panelDragStartPosition = panelPosition
                    }
            )
    }
}

private struct PerceptionEyeMenu: View {
    @Environment(ToolState.self) private var toolState
    @State private var isExpanded = false

    var body: some View {
        @Bindable var toolState = toolState

        VStack(spacing: 12) {
            if isExpanded {
                VStack(spacing: 18) {
                    perceptionOption(
                        tool: .cvdLens,
                        systemImage: "eye",
                        label: "Color Blindness"
                    )

                    perceptionOption(
                        tool: .lowVision,
                        systemImage: "eye.trianglebadge.exclamationmark",
                        label: "Low Vision"
                    )

                    perceptionOption(
                        tool: .dyslexia,
                        systemImage: "textformat",
                        label: "Dyslexia"
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.94, anchor: .bottom)))
            }

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    isExpanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(toolState.isPerceptionEnabled ? 0.24 : 0.13))
                        .frame(width: 76, height: 76)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(isExpanded ? 0.95 : 0.50), lineWidth: isExpanded ? 2.0 : 1.1)
                        }
                        .shadow(color: .white.opacity(isExpanded ? 0.18 : 0.08), radius: isExpanded ? 14 : 8)

                    Image(systemName: "eye.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(isExpanded ? 1.03 : 1.0)
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
        }
        .padding(.horizontal, 14)
        .padding(.top, isExpanded ? 18 : 12)
        .padding(.bottom, 12)
        .background {
            Capsule(style: .continuous)
                .fill(.white.opacity(0.07))
                .glassBackgroundEffect()
        }
    }

    private func perceptionOption(tool: SightTool, systemImage: String, label: String) -> some View {
        Button {
            select(tool)
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(toolState.selectedPerception == tool ? .white.opacity(0.32) : .white.opacity(0.13))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(toolState.selectedPerception == tool ? 0.95 : 0.34), lineWidth: toolState.selectedPerception == tool ? 1.8 : 1.0)
                        }
                        .shadow(color: .white.opacity(toolState.selectedPerception == tool ? 0.16 : 0.04), radius: toolState.selectedPerception == tool ? 10 : 4)

                    Image(systemName: systemImage)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(label)
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.62)
                    .frame(width: 76)
            }
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }

    private func select(_ perception: SightTool) {
        toolState.selectedPerception = perception
        toolState.isPerceptionEnabled = true
    }
}
