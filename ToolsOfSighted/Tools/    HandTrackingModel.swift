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

    struct PalmAttachmentTransform {
        var position: SIMD3<Float> = [0, 0, 0]
        var right: SIMD3<Float> = [1, 0, 0]
        var up: SIMD3<Float> = [0, 1, 0]
        var normal: SIMD3<Float> = [0, 0, 1]
        var isTracked: Bool = false
    }

    private let session = ARKitSession()
    private let handTrackingProvider = HandTrackingProvider()
    private var isRunning = false

    var tools: [FingertipTool] = [
        FingertipTool(
            id: "simulatorControls",
            attachmentID: "tool-simulator",
            title: "Contrast",
            systemImage: "checkmark.shield"
        ),
        FingertipTool(
            id: "contrast",
            attachmentID: "tool-contrast",
            title: "Contrast",
            systemImage: "checkmark.shield"
        ),
        FingertipTool(
            id: "borders",
            attachmentID: "tool-borders",
            title: "Lens",
            systemImage: "circle.dashed"
        ),
        FingertipTool(
            id: "symbols",
            attachmentID: "tool-symbols",
            title: "Lens",
            systemImage: "circle.dashed"
        )
    ]

    private var smoothedToolPositions: [String: SIMD3<Float>] = [:]
    var toolsAreSuppressed: Bool = false
    private var previousPinchStates: [String: Bool] = [:]
    private var pressCandidateToolID: String?
    private var pressCandidateStartDate: Date?
    private var hasFiredCurrentPress = false
    var activatedToolID: String?
    var palmAttachmentTransform = PalmAttachmentTransform()
    private var smoothedPalmAttachmentPosition: SIMD3<Float>?

    private let pinchActivationDistance: Float = 0.023
    private let pinchReleaseDistance: Float = 0.044
    private let pressDebounceDuration: TimeInterval = 0.16
    private let toolRevealHoldDuration: TimeInterval = 0.05
    private let toolHideHoldDuration: TimeInterval = 0.10
    private let fingertipForwardOffset: Float = 0.016
    private let fingertipVerticalOffset: Float = 0.000
    private let fingertipSmoothing: Float = 0.30
    private let palmAttachmentSmoothing: Float = 0.28
    private let trackingLossGraceDuration: TimeInterval = 0.90
    private var lastTrackedUpdateDate = Date()
    private var toolRevealGestureStartDate: Date?
    private var toolHideGestureStartDate: Date?
    private var areToolsGestureVisible = false

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
                    hideToolsIfTrackingHasBeenLostTooLong()
                    continue
                }

                guard handAnchor.chirality == .left else {
                    continue
                }

                lastTrackedUpdateDate = Date()
                updateToolPositions(using: handAnchor)
            }
        } catch {
            hideTools()
        }
    }

    private func updateToolPositions(using handAnchor: HandAnchor) {
        guard let handSkeleton = handAnchor.handSkeleton else {
            hideToolsIfTrackingHasBeenLostTooLong()
            return
        }

        guard !toolsAreSuppressed else {
            hideVisibleToolsOnly()
            return
        }

        updatePalmAttachmentTransform(handAnchor: handAnchor, handSkeleton: handSkeleton)

        let shouldRevealTools = shouldRevealTools(handAnchor: handAnchor, handSkeleton: handSkeleton)
        let shouldForceHideTools = shouldForceHideTools(handAnchor: handAnchor, handSkeleton: handSkeleton)
        updateToolRevealGate(shouldRevealTools: shouldRevealTools, shouldForceHideTools: shouldForceHideTools)

        guard areToolsGestureVisible || isPressInProgress else {
            hideVisibleToolsOnly()
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

    private func updatePalmAttachmentTransform(handAnchor: HandAnchor, handSkeleton: HandSkeleton) {
        guard
            let wrist = worldPosition(for: .wrist, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let indexMetacarpal = worldPosition(for: .indexFingerMetacarpal, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let middleMetacarpal = worldPosition(for: .middleFingerMetacarpal, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let littleMetacarpal = worldPosition(for: .littleFingerMetacarpal, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let littleTip = worldPosition(for: .littleFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton)
        else {
            palmAttachmentTransform.isTracked = false
            smoothedPalmAttachmentPosition = nil
            return
        }

        let acrossPalm = safeNormalize(indexMetacarpal - littleMetacarpal, fallback: [1, 0, 0])
        let palmUp = safeNormalize(middleMetacarpal - wrist, fallback: [0, 1, 0])
        let palmNormal = safeNormalize(simd_cross(acrossPalm, palmUp), fallback: [0, 0, 1])

        let pinkySideDirection = -acrossPalm

        let sideOffset: Float = 0.000
        let verticalOffset: Float = -0.004
        let frontOffset: Float = 0.000

        let targetPosition = littleTip
            + pinkySideDirection * sideOffset
            + palmUp * verticalOffset
            + palmNormal * frontOffset

        let currentPosition = smoothedPalmAttachmentPosition ?? targetPosition
        let smoothedPosition = currentPosition + (targetPosition - currentPosition) * palmAttachmentSmoothing
        smoothedPalmAttachmentPosition = smoothedPosition

        palmAttachmentTransform = PalmAttachmentTransform(
            position: smoothedPosition,
            right: pinkySideDirection,
            up: palmUp,
            normal: palmNormal,
            isTracked: true
        )
    }

    private var isPressInProgress: Bool {
        tools.contains { $0.isPressed } || pressCandidateToolID != nil
    }

    private func shouldRevealTools(handAnchor: HandAnchor, handSkeleton: HandSkeleton) -> Bool {
        guard
            let wrist = worldPosition(for: .wrist, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let indexTip = worldPosition(for: .indexFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let middleTip = worldPosition(for: .middleFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let ringTip = worldPosition(for: .ringFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let littleTip = worldPosition(for: .littleFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let indexKnuckle = worldPosition(for: .indexFingerMetacarpal, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let littleKnuckle = worldPosition(for: .littleFingerMetacarpal, handAnchor: handAnchor, handSkeleton: handSkeleton)
        else {
            return false
        }

        let palmWidth = max(simd_distance(indexKnuckle, littleKnuckle), 0.055)
        let indexOpen = simd_distance(indexTip, wrist) > palmWidth * 1.12
        let middleOpen = simd_distance(middleTip, wrist) > palmWidth * 1.18
        let ringOpen = simd_distance(ringTip, wrist) > palmWidth * 1.05
        let littleOpen = simd_distance(littleTip, wrist) > palmWidth * 0.92

        let fingertipsSeparated = simd_distance(indexTip, middleTip) > 0.018
            && simd_distance(middleTip, ringTip) > 0.014
            && simd_distance(ringTip, littleTip) > 0.012

        return indexOpen && middleOpen && ringOpen && littleOpen && fingertipsSeparated
    }

    private func shouldForceHideTools(handAnchor: HandAnchor, handSkeleton: HandSkeleton) -> Bool {
        guard
            let wrist = worldPosition(for: .wrist, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let indexTip = worldPosition(for: .indexFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let middleTip = worldPosition(for: .middleFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let ringTip = worldPosition(for: .ringFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let littleTip = worldPosition(for: .littleFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let indexKnuckle = worldPosition(for: .indexFingerMetacarpal, handAnchor: handAnchor, handSkeleton: handSkeleton),
            let littleKnuckle = worldPosition(for: .littleFingerMetacarpal, handAnchor: handAnchor, handSkeleton: handSkeleton)
        else {
            return false
        }

        let palmWidth = max(simd_distance(indexKnuckle, littleKnuckle), 0.055)
        let indexFolded = simd_distance(indexTip, wrist) < palmWidth * 0.92
        let middleFolded = simd_distance(middleTip, wrist) < palmWidth * 0.98
        let ringFolded = simd_distance(ringTip, wrist) < palmWidth * 0.92
        let littleFolded = simd_distance(littleTip, wrist) < palmWidth * 0.88

        return indexFolded && middleFolded && ringFolded && littleFolded
    }

    private func updateToolRevealGate(shouldRevealTools: Bool, shouldForceHideTools: Bool) {
        let now = Date()

        if shouldForceHideTools {
            toolRevealGestureStartDate = nil

            guard !isPressInProgress else {
                return
            }

            if toolHideGestureStartDate == nil {
                toolHideGestureStartDate = now
            }

            if let startDate = toolHideGestureStartDate,
               now.timeIntervalSince(startDate) >= toolHideHoldDuration {
                areToolsGestureVisible = false
                hideVisibleToolsOnly()
            }

            return
        }

        if shouldRevealTools {
            toolHideGestureStartDate = nil

            if toolRevealGestureStartDate == nil {
                toolRevealGestureStartDate = now
            }

            if let startDate = toolRevealGestureStartDate,
               now.timeIntervalSince(startDate) >= toolRevealHoldDuration {
                areToolsGestureVisible = true
            }
        } else {
            toolRevealGestureStartDate = nil

            guard !areToolsGestureVisible else {
                return
            }

            if toolHideGestureStartDate == nil {
                toolHideGestureStartDate = now
            }

            if let startDate = toolHideGestureStartDate,
               now.timeIntervalSince(startDate) >= toolHideHoldDuration {
                areToolsGestureVisible = false
                hideVisibleToolsOnly()
            }
        }
    }

    private func hideVisibleToolsOnly() {
        for index in tools.indices {
            tools[index].isVisible = false
            tools[index].isPressed = false
        }
        previousPinchStates.removeAll()
        pressCandidateToolID = nil
        pressCandidateStartDate = nil
        hasFiredCurrentPress = false
    }

    private func safeNormalize(_ vector: SIMD3<Float>, fallback: SIMD3<Float>) -> SIMD3<Float> {
        let length = simd_length(vector)
        guard length > 0.0001 else {
            return fallback
        }
        return vector / length
    }

    private func updatePinchActivation(handAnchor: HandAnchor, handSkeleton: HandSkeleton) {
        guard areToolsGestureVisible,
              let thumbTipPosition = worldPosition(
                for: .thumbTip,
                handAnchor: handAnchor,
                handSkeleton: handSkeleton
              ) else {
            return
        }

        let pinchTargets: [(toolID: String, jointName: HandSkeleton.JointName)] = [
            ("simulatorControls", .indexFingerTip),
            ("contrast", .middleFingerTip),
            ("borders", .ringFingerTip),
            ("symbols", .littleFingerTip)
        ]

        var nearestCandidate: (toolID: String, distance: Float)?

        for target in pinchTargets {
            let visibleToolPosition = tools.first { $0.id == target.toolID }?.position

            guard let fingerTipPosition = worldPosition(
                for: target.jointName,
                handAnchor: handAnchor,
                handSkeleton: handSkeleton
            ) ?? visibleToolPosition else {
                setToolPressed(id: target.toolID, isPressed: false)
                continue
            }

            let distance = simd_distance(thumbTipPosition, fingerTipPosition)

            if distance < pinchActivationDistance {
                if nearestCandidate == nil || distance < nearestCandidate!.distance {
                    nearestCandidate = (target.toolID, distance)
                }
            }

            let wasPinching = previousPinchStates[target.toolID] ?? false
            let isStillPinching = wasPinching && distance < pinchReleaseDistance
            previousPinchStates[target.toolID] = isStillPinching
        }

        let now = Date()

        if let nearestCandidate {
            if pressCandidateToolID != nearestCandidate.toolID {
                pressCandidateToolID = nearestCandidate.toolID
                pressCandidateStartDate = now
                hasFiredCurrentPress = false
            }

            for target in pinchTargets {
                setToolPressed(id: target.toolID, isPressed: target.toolID == nearestCandidate.toolID)
            }

            if !hasFiredCurrentPress,
               let startDate = pressCandidateStartDate,
               now.timeIntervalSince(startDate) >= pressDebounceDuration {
                activatedToolID = nearestCandidate.toolID
                hasFiredCurrentPress = true
                previousPinchStates[nearestCandidate.toolID] = true
            }
        } else {
            let anyStillHeld = pinchTargets.contains { target in
                previousPinchStates[target.toolID] == true
            }

            if !anyStillHeld {
                pressCandidateToolID = nil
                pressCandidateStartDate = nil
                hasFiredCurrentPress = false
                clearPressedState()
            }
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
            if smoothedToolPositions[id] != nil {
                setToolVisibility(id: id, isVisible: true)
            }
            return
        }

        let wristPosition = worldPosition(
            for: .wrist,
            handAnchor: handAnchor,
            handSkeleton: handSkeleton
        )

        let fingerDirection = wristPosition.map { wrist in
            safeNormalize(fingertipPosition - wrist, fallback: [0, 1, 0])
        } ?? SIMD3<Float>(0, 1, 0)

        let perToolSideOffset: Float
        switch id {
        case "simulatorControls":
            perToolSideOffset = -0.002
        case "contrast":
            perToolSideOffset = 0.000
        case "borders":
            perToolSideOffset = 0.001
        case "symbols":
            perToolSideOffset = 0.003
        default:
            perToolSideOffset = 0.000
        }

        let sidewaysDirection = safeNormalize(simd_cross(fingerDirection, [0, 1, 0]), fallback: [1, 0, 0])
        let targetPosition = fingertipPosition
            + fingerDirection * fingertipForwardOffset
            + sidewaysDirection * perToolSideOffset
            + SIMD3<Float>(0, fingertipVerticalOffset, 0)

        let currentPosition = smoothedToolPositions[id] ?? targetPosition
        let smoothedPosition = currentPosition + (targetPosition - currentPosition) * fingertipSmoothing
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

    func activateToolFromTap(id: String) {
        activatedToolID = id
        setToolPressed(id: id, isPressed: true)
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

    private func hideToolsIfTrackingHasBeenLostTooLong() {
        let timeSinceLastTrackedUpdate = Date().timeIntervalSince(lastTrackedUpdateDate)

        guard timeSinceLastTrackedUpdate > trackingLossGraceDuration else {
            return
        }

        hideTools()
    }

    private func hideTools() {
        previousPinchStates.removeAll()
        pressCandidateToolID = nil
        pressCandidateStartDate = nil
        hasFiredCurrentPress = false
        activatedToolID = nil
        palmAttachmentTransform.isTracked = false
        smoothedPalmAttachmentPosition = nil
        smoothedToolPositions.removeAll()
        lastTrackedUpdateDate = Date()
        toolRevealGestureStartDate = nil
        toolHideGestureStartDate = nil
        areToolsGestureVisible = false
        clearPressedState()

        for index in tools.indices {
            tools[index].isVisible = false
            tools[index].isPressed = false
        }
    }
}
