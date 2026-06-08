
import SwiftUI
import UniformTypeIdentifiers
import RealityKit
import RealityKitContent

private struct CVDPaletteDots: View {
    let type: ToolState.CVDType

    private var colors: [Color] {
        switch type {
        case .protanopia:
            return [
                Color(red: 0.78, green: 0.76, blue: 0.00),
                Color(red: 1.00, green: 0.95, blue: 0.00),
                Color(red: 0.62, green: 0.62, blue: 0.48),
                Color(red: 0.70, green: 0.66, blue: 1.00)
            ]
        case .deuteranopia:
            return [
                Color(red: 0.78, green: 0.76, blue: 0.00),
                Color(red: 1.00, green: 0.95, blue: 0.00),
                Color(red: 0.62, green: 0.62, blue: 0.48),
                Color(red: 0.10, green: 0.12, blue: 0.95)
            ]
        case .tritanopia:
            return [
                Color(red: 0.86, green: 0.02, blue: 0.00),
                Color(red: 1.00, green: 0.62, blue: 0.68),
                Color(red: 0.20, green: 0.60, blue: 0.62),
                Color(red: 0.05, green: 0.78, blue: 0.78)
            ]
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Circle()
                    .fill(colors[0])
                    .frame(width: 11, height: 11)
                Circle()
                    .fill(colors[1])
                    .frame(width: 11, height: 11)
            }

            HStack(spacing: 5) {
                Circle()
                    .fill(colors[2])
                    .frame(width: 11, height: 11)
                Circle()
                    .fill(colors[3])
                    .frame(width: 11, height: 11)
            }
        }
    }

}

private struct FlowerPaletteToolIcon: View {
    private let petals: [Color] = [
        Color(red: 1.00, green: 0.78, blue: 0.22),
        Color(red: 0.76, green: 0.82, blue: 0.34),
        Color(red: 0.30, green: 0.74, blue: 0.76),
        Color(red: 0.35, green: 0.43, blue: 0.70),
        Color(red: 0.62, green: 0.34, blue: 0.74),
        Color(red: 0.84, green: 0.38, blue: 0.62),
        Color(red: 0.93, green: 0.30, blue: 0.30),
        Color(red: 1.00, green: 0.55, blue: 0.22),
        Color(red: 1.00, green: 0.68, blue: 0.20)
    ]

    var body: some View {
        ZStack {
            ForEach(petals.indices, id: \.self) { index in
                Capsule()
                    .fill(petals[index].opacity(0.72))
                    .frame(width: 18, height: 36)
                    .offset(y: -18)
                    .rotationEffect(.degrees(Double(index) * 360.0 / Double(petals.count)))
                    .blendMode(.multiply)
            }

            Circle()
                .fill(.white.opacity(0.92))
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        }
        .frame(width: 64, height: 64)
    }
}

struct FingertipToolsImmersiveView: View {
    @Environment(ToolState.self) private var toolState
    @Environment(\.openWindow) private var openWindow
    @State private var designReviewState = DesignReviewState()
    @State private var handTrackingModel = HandTrackingModel()
    @State private var selectedToolID: String?
    @State private var settingsPanelPosition: SIMD3<Float> = [0.28, 1.25, -0.85]
    @State private var panelDragStartPosition: SIMD3<Float> = [0.28, 1.25, -0.85]
    @State private var sampleDesignPosition: SIMD3<Float> = [0.0, 1.00, -1.05]
    @State private var sampleDesignDragStartPosition: SIMD3<Float> = [0.0, 1.00, -1.05]
    @State private var designSourceControlPosition: SIMD3<Float> = [0.0, 1.48, -0.88]
    @State private var designSourceControlDragStartPosition: SIMD3<Float> = [0.0, 1.48, -0.88]
    @State private var realityLensPanelPosition: SIMD3<Float> = [0.0, 1.05, -0.95]
    @State private var realityLensPanelDragStartPosition: SIMD3<Float> = [0.0, 1.05, -0.95]
    @State private var activeSpatialDragEntityName: String?
    @State private var isTestingWithoutHands = false
    @State private var filterOverlayPosition: SIMD3<Float> = [0.0, 1.18, -0.22]
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
                sampleDesign.position = sampleDesignPosition
                sampleDesign.orientation = orientationFacingUser(from: sampleDesignPosition)
                sampleDesign.scale = [0.96, 0.96, 0.96]
                sampleDesign.isEnabled = shouldShowSampleDesignCanvas
                content.add(sampleDesign)
            }

            if let sampleDesignDragHandle = attachments.entity(for: "SampleDesignCanvasDragHandle") {
                sampleDesignDragHandle.name = "SampleDesignCanvasDragHandle"
                prepareSpatialPanel(sampleDesignDragHandle, collisionSize: [0.42, 0.07, 0.04])
                sampleDesignDragHandle.position = sampleDesignDragHandlePosition
                sampleDesignDragHandle.orientation = orientationFacingUser(from: sampleDesignPosition)
                sampleDesignDragHandle.scale = [0.96, 0.96, 0.96]
                sampleDesignDragHandle.isEnabled = shouldShowSampleDesignCanvas
                content.add(sampleDesignDragHandle)
            }

            if let designSourceControl = attachments.entity(for: "DesignSourceControlPanel") {
                designSourceControl.name = "DesignSourceControlPanel"
                designSourceControl.position = designSourceControlPosition
                designSourceControl.orientation = orientationFacingUser(from: designSourceControlPosition)
                designSourceControl.scale = [1.12, 1.12, 1.12]
                designSourceControl.isEnabled = true
                content.add(designSourceControl)
            }


            let fullSceneFilterDome = makeFullSceneFilterDome()
            content.add(fullSceneFilterDome)

            if let filterOverlay = attachments.entity(for: "FullSceneFilterOverlay") {
                filterOverlay.name = "FullSceneFilterOverlay"
                filterOverlay.position = filterOverlayPosition
                filterOverlay.orientation = orientationFacingUser(from: filterOverlayPosition)
                filterOverlay.scale = [42.0, 42.0, 1.0]
                filterOverlay.isEnabled = false
                content.add(filterOverlay)
            }

            if let adjustmentOverlay = attachments.entity(for: "AdjustmentToolsOverlay") {
                adjustmentOverlay.name = "AdjustmentToolsOverlay"
                adjustmentOverlay.position = filterOverlayPosition
                adjustmentOverlay.orientation = orientationFacingUser(from: filterOverlayPosition)
                adjustmentOverlay.scale = [42.0, 42.0, 1.0]
                adjustmentOverlay.isEnabled = toolState.isToolEnabled && toolState.selectedAdjustmentTool != nil
                content.add(adjustmentOverlay)
            }

            if let realityLensOverlay = attachments.entity(for: "FloatingRealityLensOverlay") {
                realityLensOverlay.name = "FloatingRealityLensOverlay"
                realityLensOverlay.position = realityLensPanelPosition
                realityLensOverlay.orientation = orientationFacingUser(from: realityLensPanelPosition)
                realityLensOverlay.scale = [1.0, 1.0, 1.0]
                realityLensOverlay.isEnabled = shouldShowFloatingRealityLens
                content.add(realityLensOverlay)
            }

            if let toolSettingsPanel = attachments.entity(for: "FingertipToolSettingsPanel") {
                toolSettingsPanel.name = "FingertipToolSettingsPanel"
                toolSettingsPanel.position = settingsPanelPosition
                toolSettingsPanel.orientation = orientationFacingUser(from: settingsPanelPosition)
                toolSettingsPanel.scale = [0.68, 0.68, 0.68]
                toolSettingsPanel.isEnabled = selectedToolID != nil && toolState.selectedAdjustmentTool != nil
                content.add(toolSettingsPanel)
            }

            if let toolSettingsPanelDragHandle = attachments.entity(for: "FingertipToolSettingsPanelDragHandle") {
                toolSettingsPanelDragHandle.name = "FingertipToolSettingsPanelDragHandle"
                prepareSpatialPanel(toolSettingsPanelDragHandle, collisionSize: [0.28, 0.055, 0.04])
                toolSettingsPanelDragHandle.position = toolSettingsPanelDragHandlePosition
                toolSettingsPanelDragHandle.orientation = orientationFacingUser(from: settingsPanelPosition)
                toolSettingsPanelDragHandle.scale = [0.68, 0.68, 0.68]
                toolSettingsPanelDragHandle.isEnabled = selectedToolID != nil && toolState.selectedAdjustmentTool != nil
                content.add(toolSettingsPanelDragHandle)
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

                sampleDesign.position = sampleDesignPosition
                sampleDesign.orientation = orientationFacingUser(from: sampleDesignPosition)
                sampleDesign.scale = [0.96, 0.96, 0.96]
                sampleDesign.isEnabled = shouldShowSampleDesignCanvas
            }

            if let sampleDesignDragHandle = attachments.entity(for: "SampleDesignCanvasDragHandle") {
                if sampleDesignDragHandle.parent == nil {
                    content.add(sampleDesignDragHandle)
                }

                prepareSpatialPanel(sampleDesignDragHandle, collisionSize: [0.42, 0.07, 0.04])
                sampleDesignDragHandle.position = sampleDesignDragHandlePosition
                sampleDesignDragHandle.orientation = orientationFacingUser(from: sampleDesignPosition)
                sampleDesignDragHandle.scale = [0.96, 0.96, 0.96]
                sampleDesignDragHandle.isEnabled = shouldShowSampleDesignCanvas
            }

            if let designSourceControl = attachments.entity(for: "DesignSourceControlPanel") {
                if designSourceControl.parent == nil {
                    content.add(designSourceControl)
                }

                designSourceControl.position = designSourceControlPosition
                designSourceControl.orientation = orientationFacingUser(from: designSourceControlPosition)
                designSourceControl.scale = [1.12, 1.12, 1.12]
                designSourceControl.isEnabled = true
            }


            if let fullSceneFilterDome = content.entities.first(where: { $0.name == "FullSceneFilterDome" }) as? ModelEntity {
                updateFullSceneFilterDome(fullSceneFilterDome)
            } else {
                content.add(makeFullSceneFilterDome())
            }

            if let filterOverlay = attachments.entity(for: "FullSceneFilterOverlay") {
                if filterOverlay.parent == nil {
                    content.add(filterOverlay)
                }

                filterOverlay.position = filterOverlayPosition
                filterOverlay.orientation = orientationFacingUser(from: filterOverlayPosition)
                filterOverlay.scale = [42.0, 42.0, 1.0]
                filterOverlay.isEnabled = false
            }

            if let adjustmentOverlay = attachments.entity(for: "AdjustmentToolsOverlay") {
                if adjustmentOverlay.parent == nil {
                    content.add(adjustmentOverlay)
                }

                adjustmentOverlay.position = filterOverlayPosition
                adjustmentOverlay.orientation = orientationFacingUser(from: filterOverlayPosition)
                adjustmentOverlay.scale = [42.0, 42.0, 1.0]
                adjustmentOverlay.isEnabled = toolState.isToolEnabled && toolState.selectedAdjustmentTool != nil
            }

            if let realityLensOverlay = attachments.entity(for: "FloatingRealityLensOverlay") {
                if realityLensOverlay.parent == nil {
                    content.add(realityLensOverlay)
                }

                realityLensOverlay.position = realityLensPanelPosition
                realityLensOverlay.orientation = orientationFacingUser(from: realityLensPanelPosition)
                realityLensOverlay.scale = [1.0, 1.0, 1.0]
                realityLensOverlay.isEnabled = shouldShowFloatingRealityLens
            }

            if let toolSettingsPanel = attachments.entity(for: "FingertipToolSettingsPanel") {
                if toolSettingsPanel.parent == nil {
                    content.add(toolSettingsPanel)
                }

                toolSettingsPanel.position = settingsPanelPosition
                toolSettingsPanel.orientation = orientationFacingUser(from: settingsPanelPosition)
                toolSettingsPanel.scale = [0.68, 0.68, 0.68]
                toolSettingsPanel.isEnabled = selectedToolID != nil && toolState.selectedAdjustmentTool != nil
            }

            if let toolSettingsPanelDragHandle = attachments.entity(for: "FingertipToolSettingsPanelDragHandle") {
                if toolSettingsPanelDragHandle.parent == nil {
                    content.add(toolSettingsPanelDragHandle)
                }

                prepareSpatialPanel(toolSettingsPanelDragHandle, collisionSize: [0.28, 0.055, 0.04])
                toolSettingsPanelDragHandle.position = toolSettingsPanelDragHandlePosition
                toolSettingsPanelDragHandle.orientation = orientationFacingUser(from: settingsPanelPosition)
                toolSettingsPanelDragHandle.scale = [0.68, 0.68, 0.68]
                toolSettingsPanelDragHandle.isEnabled = selectedToolID != nil && toolState.selectedAdjustmentTool != nil
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

            Attachment(id: "SampleDesignCanvasDragHandle") {
                Capsule()
                    .fill(.white.opacity(0.42))
                    .frame(width: 118, height: 6)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
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
                    .frame(width: 7000, height: 5200)
                    .contentShape(Rectangle())
                    .allowsHitTesting(false)
            }

            Attachment(id: "AdjustmentToolsOverlay") {
                AdjustmentToolsOverlay()
                    .frame(width: 7000, height: 5200)
                    .contentShape(Rectangle())
                    .allowsHitTesting(false)
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

            Attachment(id: "FingertipToolSettingsPanelDragHandle") {
                Capsule()
                    .fill(.white.opacity(0.001))
                    .frame(width: 220, height: 44)
                    .contentShape(Rectangle())
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
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    handleSpatialPanelDragChanged(value)
                }
                .onEnded { value in
                    handleSpatialPanelDragEnded(value)
                }
        )
    }

    private var toolSettingsPanelDragHandlePosition: SIMD3<Float> {
        settingsPanelPosition + SIMD3<Float>(0.0, -0.205, 0.012)
    }

    private var sampleDesignDragHandlePosition: SIMD3<Float> {
        let verticalOffset: Float = designReviewState.activeSource == .importedImage ? -0.355 : -0.215
        return sampleDesignPosition + SIMD3<Float>(0.0, verticalOffset, 0.012)
    }


    private func prepareSpatialPanel(_ entity: Entity, collisionSize: SIMD3<Float>) {
        entity.components.set(InputTargetComponent())
        entity.components.set(CollisionComponent(shapes: [
            .generateBox(size: collisionSize)
        ]))
    }

    private func orientationFacingUser(from position: SIMD3<Float>) -> simd_quatf {
        let viewerPosition = SIMD3<Float>(0.0, 1.25, 0.0)
        let direction = viewerPosition - position
        let yaw = atan2(direction.x, direction.z)
        return simd_quatf(angle: yaw, axis: [0, 1, 0])
    }

    private func makeFullSceneFilterDome() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 8.0)
        let entity = ModelEntity(mesh: mesh, materials: [fullSceneFilterDomeMaterial()])
        entity.name = "FullSceneFilterDome"
        entity.position = [0.0, 1.20, 0.0]
        entity.scale = [-1.0, 1.0, 1.0]
        entity.isEnabled = shouldShowFullSceneFilterOverlay
        return entity
    }

    private func updateFullSceneFilterDome(_ entity: ModelEntity) {
        entity.position = [0.0, 1.20, 0.0]
        entity.scale = [-1.0, 1.0, 1.0]
        entity.model?.materials = [fullSceneFilterDomeMaterial()]
        entity.isEnabled = shouldShowFullSceneFilterOverlay
    }

    private func fullSceneFilterDomeMaterial() -> UnlitMaterial {
        let tint = fullSceneFilterTintUIColor()
        var material = UnlitMaterial(color: tint)
        material.blending = .transparent(opacity: .init(floatLiteral: Float(fullSceneFilterOpacity)))
        return material
    }

    private var fullSceneFilterOpacity: Double {
        min(max(Double(toolState.cvdIntensity) * 0.34, 0.0), 0.40)
    }

    private func fullSceneFilterTintUIColor() -> UIColor {
        switch toolState.selectedCVDType {
        case .protanopia:
            return UIColor(red: 0.72, green: 0.69, blue: 0.30, alpha: 1.0)
        case .deuteranopia:
            return UIColor(red: 0.62, green: 0.68, blue: 0.25, alpha: 1.0)
        case .tritanopia:
            return UIColor(red: 0.78, green: 0.48, blue: 0.50, alpha: 1.0)
        }
    }

    private func handleSpatialPanelDragChanged(_ value: EntityTargetValue<DragGesture.Value>) {
        let entityName = value.entity.name

        guard isSpatialPanelName(entityName), let parent = value.entity.parent else {
            return
        }

        if activeSpatialDragEntityName != entityName {
            activeSpatialDragEntityName = entityName
            syncDragStartPosition(for: entityName)
        }

        let currentLocation = value.convert(value.location3D, from: .local, to: parent)
        let startLocation = value.convert(value.startLocation3D, from: .local, to: parent)

        let horizontalSensitivity: Float = 1.18
        let verticalSensitivity: Float = 1.05
        let spatialDepthSensitivity: Float = 0.38
        let screenDepthSensitivity: Float = 0.00055

        let spatialDelta = SIMD3<Float>(
            Float(currentLocation.x - startLocation.x) * horizontalSensitivity,
            Float(currentLocation.y - startLocation.y) * verticalSensitivity,
            Float(currentLocation.z - startLocation.z) * spatialDepthSensitivity
        )

        let screenDepthDelta = Float(value.translation.height) * screenDepthSensitivity
        let delta = SIMD3<Float>(
            spatialDelta.x,
            spatialDelta.y,
            spatialDelta.z + screenDepthDelta
        )

        moveSpatialPanel(named: entityName, by: delta)
    }

    private func handleSpatialPanelDragEnded(_ value: EntityTargetValue<DragGesture.Value>) {
        let entityName = value.entity.name

        guard isSpatialPanelName(entityName) else {
            return
        }

        syncDragStartPosition(for: entityName)
        activeSpatialDragEntityName = nil
    }

    private func isSpatialPanelName(_ entityName: String) -> Bool {
        entityName == "FingertipToolSettingsPanelDragHandle" ||
        entityName == "SampleDesignCanvasDragHandle"
    }

    private func syncDragStartPosition(for entityName: String) {
        switch entityName {
        case "FingertipToolSettingsPanelDragHandle":
            panelDragStartPosition = settingsPanelPosition
        case "SampleDesignCanvasDragHandle":
            sampleDesignDragStartPosition = sampleDesignPosition
        default:
            break
        }
    }

    private func moveSpatialPanel(named entityName: String, by delta: SIMD3<Float>) {
        switch entityName {
        case "FingertipToolSettingsPanelDragHandle":
            settingsPanelPosition = clampedToolPanelPosition(panelDragStartPosition + delta)
        case "SampleDesignCanvasDragHandle":
            sampleDesignPosition = clampedSampleDesignPosition(sampleDesignDragStartPosition + delta)
        default:
            break
        }
    }

    private func clampedToolPanelPosition(_ position: SIMD3<Float>) -> SIMD3<Float> {
        SIMD3<Float>(
            min(max(position.x, -4.0), 4.0),
            min(max(position.y, -1.0), 3.2),
            min(max(position.z, -5.0), 1.2)
        )
    }

    private func clampedSampleDesignPosition(_ position: SIMD3<Float>) -> SIMD3<Float> {
        SIMD3<Float>(
            min(max(position.x, -4.0), 4.0),
            min(max(position.y, -1.0), 3.2),
            min(max(position.z, -5.0), 1.2)
        )
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
            let importedSourceName = sourceName.isEmpty ? "Imported Design" : sourceName
            let payload = AccessibilityAnalysisEngine.analyzeImportedDesign(
                image: image,
                sourceName: importedSourceName
            )

            shouldHideDesignCanvasAfterCancelledImport = false
            designReviewState.useTeamImportedDesign(payload)
            designReviewState.setImportedPickImage(image, sourceName: importedSourceName)
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
        activeSpatialDragEntityName = nil
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

