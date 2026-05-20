import SwiftUI
import RealityKit
import RealityKitContent

struct FingertipToolsImmersiveView: View {
    @State private var handTrackingModel = HandTrackingModel()
    @State private var selectedToolID: String?
    
    var body: some View {
        RealityView { content, attachments in
            
            for tool in handTrackingModel.tools {
                if let toolEntity = attachments.entity(for: tool.attachmentID) {
                    toolEntity.name = tool.attachmentID
                    toolEntity.position = tool.position
                    toolEntity.isEnabled = tool.isVisible
                    content.add(toolEntity)
                }
            }
            
        } update: { content, attachments in
            
            for tool in handTrackingModel.tools {
                if let toolEntity = attachments.entity(for: tool.attachmentID) {
                    
                    if toolEntity.parent == nil {
                        content.add(toolEntity)
                    }
                    
                    toolEntity.position = tool.position
                    toolEntity.isEnabled = tool.isVisible
                }
            }
            
        } attachments: {
            ForEach(handTrackingModel.tools) { tool in
                Attachment(id: tool.attachmentID) {
                    FingertipToolButton(
                        tool: tool,
                        isSelected: selectedToolID == tool.id
                    ) {
                        selectedToolID = tool.id
                        print("Selected tool: \(tool.title)")
                    }
                }
            }
        }
        .task {
            await handTrackingModel.startTracking()
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
            .frame(width: 52, height: 52)
            .background(
                Circle()
                    .fill(isSelected ? Color.blue.opacity(0.85) : Color.white.opacity(0.18))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.85), lineWidth: 1.4)
            )
            .glassBackgroundEffect()
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }
}
