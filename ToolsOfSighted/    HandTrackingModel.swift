import SwiftUI
import RealityKit
import ARKit

@MainActor
@Observable
final class HandTrackingModel {

    struct FingertipTool: Identifiable {
        let id: String
        let attachmentID: String
        let title: String
        let systemImage: String

        var position: SIMD3<Float> = [0, 0, 0]
        var isVisible: Bool = false
        var isPressed: Bool = false
    }

    private let session = ARKitSession()
    private let handTrackingProvider = HandTrackingProvider()
    private var isRunning = false

    var tools: [FingertipTool] = [
        FingertipTool(
            id: "simulatorControls",
            attachmentID: "tool-simulator",
            title: "Sim",
            systemImage: "slider.horizontal.3"
        ),
        FingertipTool(
            id: "contrast",
            attachmentID: "tool-contrast",
            title: "Contrast",
            systemImage: "circle.lefthalf.filled"
        ),
        FingertipTool(
            id: "borders",
            attachmentID: "tool-borders",
            title: "Borders",
            systemImage: "rectangle.dashed"
        ),
        FingertipTool(
            id: "symbols",
            attachmentID: "tool-symbols",
            title: "Symbols",
            systemImage: "textformat.alt"
        )
    ]

    private var smoothedToolPositions: [String: SIMD3<Float>] = [:]
    var toolsAreSuppressed: Bool = false
    private var previousPinchStates: [String: Bool] = [:]
    var activatedToolID: String?

    func startTracking() async {
        guard !isRunning else {
            return
        }

        isRunning = true

        guard HandTrackingProvider.isSupported else {
            hideTools()
            return
        }

        do {
            try await session.run([handTrackingProvider])

            for await update in handTrackingProvider.anchorUpdates {
                let handAnchor = update.anchor

                guard handAnchor.isTracked else {
                    hideTools()
                    continue
                }

                guard handAnchor.chirality == .right else {
                    continue
                }

                updateToolPositions(using: handAnchor)
            }
        } catch {
            hideTools()
        }
    }

    private func updateToolPositions(using handAnchor: HandAnchor) {
        guard let handSkeleton = handAnchor.handSkeleton else {
            hideTools()
            return
        }

        guard !toolsAreSuppressed else {
            hideTools()
            return
        }

        updateTool(
            id: "simulatorControls",
            jointName: .indexFingerTip,
            handAnchor: handAnchor,
            handSkeleton: handSkeleton
        )

        updateTool(
            id: "contrast",
            jointName: .middleFingerTip,
            handAnchor: handAnchor,
            handSkeleton: handSkeleton
        )

        updateTool(
            id: "borders",
            jointName: .ringFingerTip,
            handAnchor: handAnchor,
            handSkeleton: handSkeleton
        )

        updateTool(
            id: "symbols",
            jointName: .littleFingerTip,
            handAnchor: handAnchor,
            handSkeleton: handSkeleton
        )

        updatePinchActivation(handAnchor: handAnchor, handSkeleton: handSkeleton)
    }

    private func updatePinchActivation(handAnchor: HandAnchor, handSkeleton: HandSkeleton) {
        guard let thumbTipPosition = worldPosition(
            for: .thumbTip,
            handAnchor: handAnchor,
            handSkeleton: handSkeleton
        ) else {
            previousPinchStates.removeAll()
            clearPressedState()
            return
        }

        let pinchTargets: [(toolID: String, jointName: HandSkeleton.JointName)] = [
            ("simulatorControls", .indexFingerTip),
            ("contrast", .middleFingerTip),
            ("borders", .ringFingerTip),
            ("symbols", .littleFingerTip)
        ]

        for target in pinchTargets {
            guard let fingerTipPosition = worldPosition(
                for: target.jointName,
                handAnchor: handAnchor,
                handSkeleton: handSkeleton
            ) else {
                previousPinchStates[target.toolID] = false
                setToolPressed(id: target.toolID, isPressed: false)
                continue
            }

            let distance = simd_distance(thumbTipPosition, fingerTipPosition)
            let isPinching = distance < 0.030
            let wasPinching = previousPinchStates[target.toolID] ?? false

            if isPinching && !wasPinching {
                activatedToolID = target.toolID
            }

            previousPinchStates[target.toolID] = isPinching
            setToolPressed(id: target.toolID, isPressed: isPinching)
        }
    }

    private func updateTool(
        id: String,
        jointName: HandSkeleton.JointName,
        handAnchor: HandAnchor,
        handSkeleton: HandSkeleton
    ) {
        guard let fingertipPosition = worldPosition(
            for: jointName,
            handAnchor: handAnchor,
            handSkeleton: handSkeleton
        ) else {
            setToolVisibility(id: id, isVisible: false)
            return
        }

        let targetPosition = fingertipPosition + SIMD3<Float>(0, 0.014, 0)
        let currentPosition = smoothedToolPositions[id] ?? targetPosition
        let smoothedPosition = currentPosition + (targetPosition - currentPosition) * 0.22
        smoothedToolPositions[id] = smoothedPosition

        if let index = tools.firstIndex(where: { $0.id == id }) {
            tools[index].position = smoothedPosition
            tools[index].isVisible = true
        }
    }

    private func worldPosition(
        for jointName: HandSkeleton.JointName,
        handAnchor: HandAnchor,
        handSkeleton: HandSkeleton
    ) -> SIMD3<Float>? {
        let joint = handSkeleton.joint(jointName)

        guard joint.isTracked else {
            return nil
        }

        let worldTransform = handAnchor.originFromAnchorTransform * joint.anchorFromJointTransform

        return SIMD3<Float>(
            worldTransform.columns.3.x,
            worldTransform.columns.3.y,
            worldTransform.columns.3.z
        )
    }

    private func setToolVisibility(id: String, isVisible: Bool) {
        if let index = tools.firstIndex(where: { $0.id == id }) {
            tools[index].isVisible = isVisible
        }
    }

    private func setToolPressed(id: String, isPressed: Bool) {
        if let index = tools.firstIndex(where: { $0.id == id }) {
            tools[index].isPressed = isPressed
        }
    }

    private func clearPressedState() {
        for index in tools.indices {
            tools[index].isPressed = false
        }
    }

    private func hideTools() {
        previousPinchStates.removeAll()
        activatedToolID = nil
        clearPressedState()

        for index in tools.indices {
            tools[index].isVisible = false
            tools[index].isPressed = false
        }
    }
}
