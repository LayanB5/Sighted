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
                handToolsMenu.position = [0.54, 1.30, -0.78]
                handToolsMenu.isEnabled = isTestingWithoutHands
                content.add(handToolsMenu)
            }

            if let perceptionEyeMenu = attachments.entity(for: "PerceptionEyeMenu") {
                perceptionEyeMenu.name = "PerceptionEyeMenu"
                perceptionEyeMenu.position = [-0.54, 0.78, -0.74]
                perceptionEyeMenu.isEnabled = true
                content.add(perceptionEyeMenu)
            }

            if let filterOverlay = attachments.entity(for: "FullSceneFilterOverlay") {
                filterOverlay.name = "FullSceneFilterOverlay"
                filterOverlay.position = filterOverlayPosition
                filterOverlay.scale = [4.8, 4.8, 1.0]
                filterOverlay.isEnabled = toolState.selectedPerception != nil && toolState.isPerceptionEnabled
                content.add(filterOverlay)
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

                handToolsMenu.position = [0.54, 1.30, -0.78]
                handToolsMenu.isEnabled = isTestingWithoutHands
            }

            if let perceptionEyeMenu = attachments.entity(for: "PerceptionEyeMenu") {
                if perceptionEyeMenu.parent == nil {
                    content.add(perceptionEyeMenu)
                }

                perceptionEyeMenu.position = [-0.54, 0.78, -0.74]
                perceptionEyeMenu.isEnabled = true
            }

            if let filterOverlay = attachments.entity(for: "FullSceneFilterOverlay") {
                if filterOverlay.parent == nil {
                    content.add(filterOverlay)
                }

                filterOverlay.position = filterOverlayPosition
                filterOverlay.scale = [4.8, 4.8, 1.0]
                filterOverlay.isEnabled = toolState.selectedPerception != nil && toolState.isPerceptionEnabled
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

            Attachment(id: "FullSceneFilterOverlay") {
                FullSceneFilterOverlay()
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
                    ForEach(SightTool.allCases) { tool in
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

                                    Text("Tool settings")
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
                            .frame(width: 230)
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

                    Text("Hand Tools")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.white.opacity(0.16), in: Capsule())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
        }
        .padding(14)
        .glassBackgroundEffect()
    }

    private func isSelected(_ tool: SightTool) -> Bool {
        selectedToolID == "test-\(tool.rawValue)" && toolState.selectedTool == tool
    }

    private func select(_ tool: SightTool) {
        selectedToolID = "test-\(tool.rawValue)"
        toolState.selectedTool = tool
        toolState.isToolEnabled = true
        settingsPanelPosition = [0.32, 1.25, -0.72]
        panelDragStartPosition = settingsPanelPosition
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

                if selectedPerception == .lowVision || selectedPerception == .blur {
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
                return Color(red: 0.75, green: 0.62, blue: 0.28)
            case .deuteranopia:
                return Color(red: 0.66, green: 0.61, blue: 0.30)
            case .tritanopia:
                return Color(red: 0.38, green: 0.56, blue: 0.72)
            }

        case .lowVision:
            return .white

        case .dyslexia:
            return Color(red: 0.95, green: 0.92, blue: 0.78)

        case .contrast:
            return .black

        case .blur:
            return .white
        }
    }

    private func overlayOpacity(for perception: SightTool) -> Double {
        switch perception {
        case .cvdLens:
            return 0.10 + toolState.cvdIntensity * 0.46

        case .lowVision:
            return 0.14 + toolState.lowVisionIntensity * 0.52

        case .dyslexia:
            return 0.04 + toolState.dyslexiaIntensity * 0.18

        case .contrast:
            return 0.06 + toolState.contrastIntensity * 0.44

        case .blur:
            return 0.14 + toolState.blurIntensity * 0.56
        }
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
        let intensity = toolState.dyslexiaIntensity

        return VStack(spacing: 42) {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.05 + intensity * 0.12))
                    .frame(width: index.isMultiple(of: 2) ? 620 : 460, height: 7)
                    .offset(x: index.isMultiple(of: 2) ? intensity * 38 : -intensity * 34)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? intensity * 2.4 : -intensity * 2.0))
            }
        }
        .opacity(0.75)
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

        VStack(spacing: 14) {
            if isExpanded {
                VStack(spacing: 18) {
                    perceptionOption(
                        tool: .cvdLens,
                        systemImage: "eye",
                        label: "CVD"
                    )

                    perceptionOption(
                        tool: .lowVision,
                        systemImage: "eye.trianglebadge.exclamationmark",
                        label: "Low"
                    )

                    perceptionOption(
                        tool: .dyslexia,
                        systemImage: "textformat",
                        label: "Text"
                    )

                    perceptionOption(
                        tool: .contrast,
                        systemImage: "circle.lefthalf.filled",
                        label: "Contrast"
                    )

                    perceptionOption(
                        tool: .blur,
                        systemImage: "camera.filters",
                        label: "Blur"
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.92, anchor: .bottom)))
            }

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    isExpanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(toolState.isPerceptionEnabled ? 0.20 : 0.10))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(isExpanded ? 0.95 : 0.55), lineWidth: isExpanded ? 2.0 : 1.2)
                        }

                    Image(systemName: "eye.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
        }
        .padding(.horizontal, 16)
        .padding(.top, isExpanded ? 22 : 14)
        .padding(.bottom, 14)
        .background {
            Capsule(style: .continuous)
                .fill(.white.opacity(0.08))
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
                        .fill(toolState.selectedPerception == tool ? .white.opacity(0.26) : .white.opacity(0.12))
                        .frame(width: 58, height: 58)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(toolState.selectedPerception == tool ? 0.95 : 0.35), lineWidth: toolState.selectedPerception == tool ? 1.8 : 1.0)
                        }

                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
