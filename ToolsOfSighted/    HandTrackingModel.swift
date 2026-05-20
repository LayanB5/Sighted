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
    }
    
    private let session = ARKitSession()
    private let handTrackingProvider = HandTrackingProvider()
    private var isRunning = false
    
    var tools: [FingertipTool] = [
        FingertipTool(id: "select", attachmentID: "tool-select", title: "Select", systemImage: "cursorarrow"),
        FingertipTool(id: "lens", attachmentID: "tool-lens", title: "Lens", systemImage: "circle.dashed"),
        FingertipTool(id: "practice", attachmentID: "tool-practice", title: "Fix", systemImage: "slider.horizontal.3"),
        FingertipTool(id: "reset", attachmentID: "tool-reset", title: "Reset", systemImage: "arrow.counterclockwise")
    ]
    
    func startTracking() async {
        guard !isRunning else { return }
        isRunning = true
        
        guard HandTrackingProvider.isSupported else { return }
        
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
        
        updateTool(id: "select", jointName: .indexFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton)
        updateTool(id: "lens", jointName: .middleFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton)
        updateTool(id: "practice", jointName: .ringFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton)
        updateTool(id: "reset", jointName: .littleFingerTip, handAnchor: handAnchor, handSkeleton: handSkeleton)
    }
    
    private func updateTool(
        id: String,
        jointName: HandSkeleton.JointName,
        handAnchor: HandAnchor,
        handSkeleton: HandSkeleton
    ) {
        let joint = handSkeleton.joint(jointName)
        
        guard joint.isTracked else {
            setToolVisibility(id: id, isVisible: false)
            return
        }
        
        let worldTransform = handAnchor.originFromAnchorTransform * joint.anchorFromJointTransform
        
        let worldPosition = SIMD3<Float>(
            worldTransform.columns.3.x,
            worldTransform.columns.3.y,
            worldTransform.columns.3.z
        )
        
        if let index = tools.firstIndex(where: { $0.id == id }) {
            tools[index].position = worldPosition + SIMD3<Float>(0, 0.025, 0)
            tools[index].isVisible = true
        }
    }
    
    private func setToolVisibility(id: String, isVisible: Bool) {
        if let index = tools.firstIndex(where: { $0.id == id }) {
            tools[index].isVisible = isVisible
        }
    }
    
    private func hideTools() {
        for index in tools.indices {
            tools[index].isVisible = false
        }
    }
}
