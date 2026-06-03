import SwiftUI
import UniformTypeIdentifiers
import RealityKit
import RealityKitContent

struct FingertipToolsImmersiveView: View {
    @Environment(ToolState.self) private var toolState
    @Environment(\.openWindow) private var openWindow
    @State private var designReviewState = DesignReviewState()
    @State private var handTrackingModel = HandTrackingModel()
    @State private var selectedToolID: String?
    @State private var settingsPanelPosition: SIMD3<Float> = [0.28, 1.25, -0.85]
    @State private var panelDragStartPosition: SIMD3<Float> = [0.28, 1.25, -0.85]
    @State private var isTestingWithoutHands = false
    @State private var filterOverlayPosition: SIMD3<Float> = [0.0, 1.18, -2.2]
    @State private var suppressToolActivationUntil = Date.distantPast
    @State private var isImportPickerPresented = false
    @State private var shouldHideDesignCanvasAfterCancelledImport = false
    @State private var realityLensOffset: CGSize = .zero
    @State private var realityLensDragStartOffset: CGSize?

    var body: some View {
        RealityView { content, attachments in
            for tool in focusedFingertipTools {
                if let toolEntity = attachments.entity(for: tool.attachmentID) {
                    toolEntity.name = tool.attachmentID
                    toolEntity.position = tool.position
                    toolEntity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
                    toolEntity.scale = [0.60, 0.60, 0.60]
                    toolEntity.isEnabled = tool.isVisible
                    content.add(toolEntity)
                }
            }

            if let sampleDesign = attachments.entity(for: "SampleDesignCanvas") {
                sampleDesign.name = "SampleDesignCanvas"
                sampleDesign.position = [0.0, 1.00, -1.05]
                sampleDesign.scale = [0.96, 0.96, 0.96]
                sampleDesign.isEnabled = shouldShowSampleDesignCanvas
                content.add(sampleDesign)
            }

            if let designSourceControl = attachments.entity(for: "DesignSourceControlPanel") {
                designSourceControl.name = "DesignSourceControlPanel"
                designSourceControl.position = [0.0, 1.48, -0.88]
                designSourceControl.scale = [1.02, 1.02, 1.02]
                designSourceControl.isEnabled = true
                content.add(designSourceControl)
            }

            if let filterOverlay = attachments.entity(for: "FullSceneFilterOverlay") {
                filterOverlay.name = "FullSceneFilterOverlay"
                filterOverlay.position = filterOverlayPosition
                filterOverlay.scale = [8.5, 8.5, 1.0]
                filterOverlay.isEnabled = shouldShowFullSceneFilterOverlay
                content.add(filterOverlay)
            }

            if let adjustmentOverlay = attachments.entity(for: "AdjustmentToolsOverlay") {
                adjustmentOverlay.name = "AdjustmentToolsOverlay"
                adjustmentOverlay.position = filterOverlayPosition
                adjustmentOverlay.scale = [8.5, 8.5, 1.0]
                adjustmentOverlay.isEnabled = toolState.isToolEnabled && toolState.selectedAdjustmentTool != nil
                content.add(adjustmentOverlay)
            }

            if let realityLensOverlay = attachments.entity(for: "FloatingRealityLensOverlay") {
                realityLensOverlay.name = "FloatingRealityLensOverlay"
                realityLensOverlay.position = [0.0, 1.05, -0.95]
                realityLensOverlay.scale = [1.0, 1.0, 1.0]
                realityLensOverlay.isEnabled = shouldShowFloatingRealityLens
                content.add(realityLensOverlay)
            }

            if let toolSettingsPanel = attachments.entity(for: "FingertipToolSettingsPanel") {
                toolSettingsPanel.name = "FingertipToolSettingsPanel"
                toolSettingsPanel.position = settingsPanelPosition
                toolSettingsPanel.scale = [0.68, 0.68, 0.68]
                toolSettingsPanel.isEnabled = selectedToolID != nil && toolState.selectedAdjustmentTool != nil
                content.add(toolSettingsPanel)
            }

        } update: { content, attachments in
            for tool in focusedFingertipTools {
                if let toolEntity = attachments.entity(for: tool.attachmentID) {
                    if toolEntity.parent == nil {
                        content.add(toolEntity)
                    }
                    toolEntity.position = tool.position
                    toolEntity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
                    toolEntity.scale = [0.60, 0.60, 0.60]
                    toolEntity.isEnabled = tool.isVisible
                }
            }

            if let sampleDesign = attachments.entity(for: "SampleDesignCanvas") {
                if sampleDesign.parent == nil {
                    content.add(sampleDesign)
                }

                sampleDesign.position = [0.0, 1.00, -1.05]
                sampleDesign.scale = [0.96, 0.96, 0.96]
                sampleDesign.isEnabled = shouldShowSampleDesignCanvas
            }

            if let designSourceControl = attachments.entity(for: "DesignSourceControlPanel") {
                if designSourceControl.parent == nil {
                    content.add(designSourceControl)
                }

                designSourceControl.position = [0.0, 1.48, -0.88]
                designSourceControl.scale = [1.02, 1.02, 1.02]
                designSourceControl.isEnabled = true
            }

            if let filterOverlay = attachments.entity(for: "FullSceneFilterOverlay") {
                if filterOverlay.parent == nil {
                    content.add(filterOverlay)
                }

                filterOverlay.position = filterOverlayPosition
                filterOverlay.scale = [8.5, 8.5, 1.0]
                filterOverlay.isEnabled = shouldShowFullSceneFilterOverlay
            }

            if let adjustmentOverlay = attachments.entity(for: "AdjustmentToolsOverlay") {
                if adjustmentOverlay.parent == nil {
                    content.add(adjustmentOverlay)
                }

                adjustmentOverlay.position = filterOverlayPosition
                adjustmentOverlay.scale = [8.5, 8.5, 1.0]
                adjustmentOverlay.isEnabled = toolState.isToolEnabled && toolState.selectedAdjustmentTool != nil
            }

            if let realityLensOverlay = attachments.entity(for: "FloatingRealityLensOverlay") {
                if realityLensOverlay.parent == nil {
                    content.add(realityLensOverlay)
                }

                realityLensOverlay.position = [0.0, 1.05, -0.95]
                realityLensOverlay.scale = [1.0, 1.0, 1.0]
                realityLensOverlay.isEnabled = shouldShowFloatingRealityLens
            }

            if let toolSettingsPanel = attachments.entity(for: "FingertipToolSettingsPanel") {
                if toolSettingsPanel.parent == nil {
                    content.add(toolSettingsPanel)
                }

                toolSettingsPanel.position = settingsPanelPosition
                toolSettingsPanel.scale = [0.68, 0.68, 0.68]
                toolSettingsPanel.isEnabled = selectedToolID != nil && toolState.selectedAdjustmentTool != nil
            }


        } attachments: {
            ForEach(focusedFingertipTools) { tool in
                Attachment(id: tool.attachmentID) {
                    FingertipToolButton(
                        tool: tool,
                        isSelected: selectedToolID == tool.id,
                        isPressed: tool.isPressed
                    ) {
                        handTrackingModel.activateToolFromTap(id: tool.id)
                        selectAdjustmentTool(with: tool.id, near: tool.position)
                    }
                }
            }

            Attachment(id: "SampleDesignCanvas") {
                SampleDesignCanvas {
                    shouldHideDesignCanvasAfterCancelledImport = true
                    isImportPickerPresented = true
                }
                .environment(designReviewState)
            }

            Attachment(id: "DesignSourceControlPanel") {
                DesignSourceControlPanel {
                    shouldHideDesignCanvasAfterCancelledImport = true
                    isImportPickerPresented = true
                }
                .environment(designReviewState)
            }

            Attachment(id: "FullSceneFilterOverlay") {
                FullSceneFilterOverlay()
                    .environment(designReviewState)
            }

            Attachment(id: "AdjustmentToolsOverlay") {
                AdjustmentToolsOverlay()
            }

            Attachment(id: "FloatingRealityLensOverlay") {
                FloatingRealityLensOverlay(
                    lensLabelTitle: floatingRealityLensLabelTitle,
                    offset: $realityLensOffset,
                    dragStartOffset: $realityLensDragStartOffset
                )
                .environment(toolState)
            }

            Attachment(id: "FingertipToolSettingsPanel") {
                FingertipToolSettingsPanel(
                    closeAction: closeSelectedTool,
                    panelPosition: $settingsPanelPosition,
                    panelDragStartPosition: $panelDragStartPosition
                )
                .environment(designReviewState)
            }

        }
        .task {
            await handTrackingModel.startTracking()
        }
        .onChange(of: handTrackingModel.activatedToolID) { _, activatedToolID in
            guard Date() >= suppressToolActivationUntil else {
                handTrackingModel.activatedToolID = nil
                return
            }

            guard let activatedToolID else {
                return
            }

            let activatedToolPosition = handTrackingModel.tools
                .first { $0.id == activatedToolID }?
                .position

            selectAdjustmentTool(with: activatedToolID, near: activatedToolPosition)
            handTrackingModel.activatedToolID = nil
        }
        .onChange(of: selectedToolID) { _, newValue in
            handTrackingModel.toolsAreSuppressed = newValue != nil
        }
        .onChange(of: toolState.selectedAdjustmentTool) { _, newValue in
            if newValue == nil {
                suppressToolActivationUntil = Date().addingTimeInterval(1.0)
                selectedToolID = nil
                handTrackingModel.activatedToolID = nil
                handTrackingModel.toolsAreSuppressed = true

                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(800))

                    if selectedToolID == nil && toolState.selectedAdjustmentTool == nil {
                        handTrackingModel.toolsAreSuppressed = false
                    }
                }
            }
        }
        .onChange(of: designReviewState.activeSource) { _, newSource in
            if newSource != .importedImage {
                shouldHideDesignCanvasAfterCancelledImport = false
            }
        }
        .fileImporter(
            isPresented: $isImportPickerPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImportedDesignResult(result)
        }
    }

    private var shouldShowFullSceneFilterOverlay: Bool {
        designReviewState.activeSource != .liveSurface &&
        toolState.selectedPerception != nil &&
        toolState.isPerceptionEnabled &&
        toolState.filterApplicationMode == .fullWorld &&
        !isImportPickerPresented
    }

    private func handleImportedDesignResult(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else {
                shouldHideDesignCanvasAfterCancelledImport = true
                return
            }

            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            guard let image = UIImage(data: data) else {
                return
            }

            let sourceName = url.deletingPathExtension().lastPathComponent
            let payload = AccessibilityAnalysisEngine.analyzeImportedDesign(
                image: image,
                sourceName: sourceName.isEmpty ? "Imported Design" : sourceName
            )

            shouldHideDesignCanvasAfterCancelledImport = false
            designReviewState.useTeamImportedDesign(payload)
        } catch {
            shouldHideDesignCanvasAfterCancelledImport = true
            print("Failed to import design file: \(error.localizedDescription)")
        }
    }
    private var shouldShowFloatingRealityLens: Bool {
        designReviewState.activeSource == .liveSurface && !isImportPickerPresented
    }

    private var floatingRealityLensLabelTitle: String {
        switch toolState.selectedCVDType {
        case .protanopia:
            return "P Lens"
        case .deuteranopia:
            return "D Lens"
        case .tritanopia:
            return "T Lens"
        }
    }

    private var shouldShowSampleDesignCanvas: Bool {
        designReviewState.activeSource != .liveSurface &&
        !isImportPickerPresented &&
        !shouldHideDesignCanvasAfterCancelledImport
    }
    private var focusedFingertipTools: [HandTrackingModel.FingertipTool] {
        handTrackingModel.tools.filter { tool in
            tool.id == "simulatorControls" || tool.id == "symbols"
        }
    }

    private var visibleToolPositions: [SIMD3<Float>] {
        focusedFingertipTools
            .filter { $0.isVisible }
            .map(\.position)
    }

    private var trackedHandPositions: [SIMD3<Float>] {
        let allPositions = focusedFingertipTools.map(\.position)
        let nonDefaultPositions = allPositions.filter { position in
            abs(position.x) > 0.001 || abs(position.y) > 0.001 || abs(position.z) > 0.001
        }

        return nonDefaultPositions.isEmpty ? visibleToolPositions : nonDefaultPositions
    }

    private var handCenterPosition: SIMD3<Float> {
        let positions = trackedHandPositions

        guard !positions.isEmpty else {
            return [0.0, 1.10, -0.75]
        }

        let total = positions.reduce(SIMD3<Float>(repeating: 0)) { partialResult, position in
            partialResult + position
        }

        return total / Float(positions.count)
    }

    private func panelPosition(near fingertipPosition: SIMD3<Float>) -> SIMD3<Float> {
        let horizontalOffset: Float = fingertipPosition.x < 0 ? 0.62 : -0.62
        let verticalOffset: Float = -0.10
        let depthOffset: Float = -0.06

        return [
            fingertipPosition.x + horizontalOffset,
            fingertipPosition.y + verticalOffset,
            fingertipPosition.z + depthOffset
        ]
    }

    private func selectAdjustmentTool(with toolID: String, near position: SIMD3<Float>? = nil) {
        guard Date() >= suppressToolActivationUntil else {
            return
        }

        guard let adjustmentTool = adjustmentTool(for: toolID) else {
            return
        }

        selectedToolID = toolID
        toolState.selectedAdjustmentTool = adjustmentTool
        toolState.isToolEnabled = true
        handTrackingModel.toolsAreSuppressed = true

        if let position {
            settingsPanelPosition = panelPosition(near: position)
        } else {
            settingsPanelPosition = [0.32, 1.25, -0.72]
        }

        panelDragStartPosition = settingsPanelPosition
    }

    private func closeSelectedTool() {
        suppressToolActivationUntil = Date().addingTimeInterval(0.55)
        selectedToolID = nil
        toolState.selectedAdjustmentTool = nil
        toolState.isToolEnabled = false
        handTrackingModel.activatedToolID = nil
        handTrackingModel.toolsAreSuppressed = false
    }

    private func adjustmentTool(for toolID: String) -> ToolState.AdjustmentTool? {
        switch toolID {
        case "simulatorControls":
            return .contrast
        case "symbols":
            return .borders
        default:
            return nil
        }
    }
}

