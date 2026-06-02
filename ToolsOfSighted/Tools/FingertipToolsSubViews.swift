//
//  FingertipToolsSubViews.swift
//  ToolsOfSighted
//
//  Created by Layan Albarrak on 01/06/2026.
//
//  UI subviews and component helpers for Fingertip Tools and Design Review.
//

import SwiftUI
import UIKit
import RealityKit

// MARK: - Floating Reality Lens

struct FloatingRealityLensOverlay: View {
    @Environment(ToolState.self) private var toolState
    let lensLabelTitle: String
    @Binding var offset: CGSize
    @Binding var dragStartOffset: CGSize?

    private let lensSize: CGFloat = 420
    private let movementSurfaceSize = CGSize(width: 5200, height: 3400)

    var body: some View {
        ZStack {
            Color.clear
                .frame(width: movementSurfaceSize.width, height: movementSurfaceSize.height)

            lensBody
                .offset(offset)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            if dragStartOffset == nil {
                                dragStartOffset = offset
                            }

                            let startOffset = dragStartOffset ?? offset
                            let proposedOffset = CGSize(
                                width: startOffset.width + value.translation.width,
                                height: startOffset.height + value.translation.height
                            )

                            offset = limitedRealityLensOffset(proposedOffset)
                        }
                        .onEnded { _ in
                            dragStartOffset = nil
                        }
                )
        }
        .frame(width: movementSurfaceSize.width, height: movementSurfaceSize.height)
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }

    private var lensBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 58, style: .continuous)
                .fill(realityLensTintColor.opacity(0.040 + toolState.cvdIntensity * 0.075))
                .blendMode(.multiply)

            RoundedRectangle(cornerRadius: 58, style: .continuous)
                .fill(.gray.opacity(0.010 + toolState.cvdIntensity * 0.030))
                .blendMode(.saturation)

            RoundedRectangle(cornerRadius: 58, style: .continuous)
                .strokeBorder(.white.opacity(0.78), lineWidth: 3.4)

            VStack(spacing: 3) {
                Image(systemName: "eye")
                    .font(.system(size: 12, weight: .semibold))

                Text(lensLabelTitle)
                    .font(.system(size: 8.5, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.90))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.black.opacity(0.48), in: Capsule())
            .offset(y: -(lensSize / 2) - 21)

            Text(activeRealityLensName)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.90))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.42), in: Capsule())
                .offset(y: (lensSize / 2) + 22)
        }
        .frame(width: lensSize, height: lensSize)
        .contentShape(RoundedRectangle(cornerRadius: 58, style: .continuous))
    }

    private var realityLensTintColor: Color {
        switch toolState.selectedCVDType {
        case .protanopia:
            return Color(red: 0.76, green: 0.62, blue: 0.30)
        case .deuteranopia:
            return Color(red: 0.70, green: 0.62, blue: 0.28)
        case .tritanopia:
            return Color(red: 0.34, green: 0.54, blue: 0.72)
        }
    }

    private func limitedRealityLensOffset(_ proposedOffset: CGSize) -> CGSize {
        let maxX = (movementSurfaceSize.width - lensSize) / 2
        let maxY = (movementSurfaceSize.height - lensSize) / 2

        return CGSize(
            width: min(max(proposedOffset.width, -maxX), maxX),
            height: min(max(proposedOffset.height, -maxY), maxY)
        )
    }

    private var activeRealityLensName: String {
        switch toolState.selectedCVDType {
        case .protanopia:
            return "P · Protanopia ready"
        case .deuteranopia:
            return "D · Deuteranopia ready"
        case .tritanopia:
            return "T · Tritanopia ready"
        }
    }
}

// MARK: - Fingertip Tool Settings Panel

struct FingertipToolSettingsPanel: View {
    @Environment(ToolState.self) private var toolState
    @Environment(DesignReviewState.self) private var designReviewState
    let closeAction: () -> Void
    @Binding var panelPosition: SIMD3<Float>
    @Binding var panelDragStartPosition: SIMD3<Float>
    @State private var isDraggingPanel = false

    var body: some View {
        @Bindable var toolState = toolState

        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: toolState.selectedAdjustmentTool == .contrast ? 0 : 12) {
                if toolState.selectedAdjustmentTool != .contrast {
                    header
                }

                controls(toolState: toolState)
            }
            .padding(toolState.selectedAdjustmentTool == .contrast ? 0 : 14)
            .frame(width: panelWidth, alignment: .topLeading)
            .background(
                usesReadableToolPanelBackground ? .regularMaterial : .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(usesReadableToolPanelBackground ? 0.22 : 0.16), lineWidth: 1)
            }

            Capsule()
                .fill(.white.opacity(0.24))
                .frame(width: 104, height: 6)
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.28), lineWidth: 0.8)
                }
                .shadow(color: .white.opacity(0.08), radius: 4, y: 1)
                .contentShape(Capsule())
                .hoverEffect(.highlight)
                .padding(.horizontal, 34)
                .padding(.vertical, 14)
                .padding(.top, -8)
                .gesture(panelDragGesture)
        }
    }

    private var panelDragGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if !isDraggingPanel {
                    panelDragStartPosition = panelPosition
                    isDraggingPanel = true
                }

                let dragScale: Float = 0.00055
                let targetPosition = SIMD3<Float>(
                    panelDragStartPosition.x + Float(value.translation.width) * dragScale,
                    panelDragStartPosition.y - Float(value.translation.height) * dragScale,
                    panelDragStartPosition.z
                )

                panelPosition = targetPosition
            }
            .onEnded { _ in
                panelDragStartPosition = panelPosition
                isDraggingPanel = false
            }
    }

    private var usesReadableToolPanelBackground: Bool {
        switch toolState.selectedAdjustmentTool {
        case .contrast, .borders, .symbols:
            return true
        case .simulatorControls, nil:
            return false
        }
    }

    private var panelWidth: CGFloat {
        switch toolState.selectedAdjustmentTool {
        case .contrast:
            return 560
        case .simulatorControls:
            return 390
        case .borders, .symbols:
            return 370
        case nil:
            return 320
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: headerIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.96))
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(panelTitle)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(panelSubtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: closeAction) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(width: 30, height: 30)
                    .background(.white.opacity(0.11), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.13), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .hoverEffect(.highlight)
        }
    }

    @ViewBuilder
    private func controls(toolState: ToolState) -> some View {
        @Bindable var toolState = toolState

        switch toolState.selectedAdjustmentTool {
        case .simulatorControls:
            ContrastToolPanel(toolState: toolState, closeAction: closeAction)

        case .contrast:
            ContrastToolPanel(toolState: toolState, closeAction: closeAction)

        case .borders:
            LensToolPanel(toolState: toolState)

        case .symbols:
            LensToolPanel(toolState: toolState)

        case nil:
            Text("Select a fingertip tool to begin.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var headerIcon: String {
        switch toolState.selectedAdjustmentTool {
        case .contrast:
            return "checkmark.shield"
        case .simulatorControls:
            return "checkmark.shield"
        case .borders, .symbols:
            return "scope"
        case nil:
            return "hand.point.up.left"
        }
    }

    private var panelTitle: String {
        switch toolState.selectedAdjustmentTool {
        case .simulatorControls:
            return "Contrast"
        case .contrast:
            return "Contrast"
        case .borders:
            return "Lens"
        case .symbols:
            return "Lens"
        case nil:
            return "Tool"
        }
    }

    private var panelSubtitle: String {
        switch toolState.selectedAdjustmentTool {
        case .simulatorControls:
            return "Manually check text and background readability."
        case .contrast:
            return "Manually check text and background readability."
        case .borders:
            return "Inspect one area without changing the whole view."
        case .symbols:
            return "Inspect one area without changing the whole view."
        case nil:
            return "Choose a tool from your fingertips."
        }
    }
}

// MARK: - Source and Filter Control

struct DesignSourceControlPanel: View {
    @Environment(ToolState.self) private var toolState
    @Environment(DesignReviewState.self) private var designReviewState
    let importAction: () -> Void
    @State private var isFilterMenuExpanded = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            sourceControlBar
            filterDock
        }
        .animation(.spring(response: 0.30, dampingFraction: 0.84), value: isFilterMenuExpanded)
    }

    private var sourceControlBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text("Source")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)

            HStack(spacing: 6) {
                ForEach(DesignReviewSourceKind.allCases) { source in
                    sourceButton(source)
                }
            }
            .padding(5)
            .background(.white.opacity(0.06), in: Capsule())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .glassBackgroundEffect()
    }

    private var filterDock: some View {
        VStack(spacing: isFilterMenuExpanded ? 7 : 0) {
            filterButton

            if isFilterMenuExpanded {
                filterOptionsPanel
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, isFilterMenuExpanded ? 7 : 5)
        .frame(width: 56)
        .background {
            Capsule(style: .continuous)
                .fill(.white.opacity(isFilterMenuExpanded ? 0.075 : 0.055))
                .glassBackgroundEffect()
        }
        .overlay {
            Capsule()
                .stroke(.white.opacity(isFilterMenuExpanded ? 0.24 : 0.14), lineWidth: 1)
        }
    }

    private var filterButton: some View {
        Button {
            isFilterMenuExpanded.toggle()
        } label: {
            ZStack {
                if isFilterMenuExpanded || toolState.isPerceptionEnabled {
                    Circle()
                        .fill(.white.opacity(isFilterMenuExpanded ? 0.18 : 0.10))
                        .frame(width: 46, height: 46)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(isFilterMenuExpanded ? 0.48 : 0.20), lineWidth: isFilterMenuExpanded ? 1.25 : 1)
                        }
                }

                Image(systemName: "eye.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.96))
            }
            .frame(width: 46, height: 46)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }

    private var filterOptionsPanel: some View {
        VStack(spacing: 7) {
            cvdOptionButton(code: "P", type: .protanopia)
            cvdOptionButton(code: "D", type: .deuteranopia)
            cvdOptionButton(code: "T", type: .tritanopia)

            Divider()
                .frame(width: 28)
                .opacity(0.16)

            Button {
                toolState.isPerceptionEnabled = false
                toolState.selectedPerception = nil
                isFilterMenuExpanded = false
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 38, height: 34)
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
        }
    }

    private func cvdOptionButton(code: String, type: ToolState.CVDType) -> some View {
        let isSelected = toolState.isPerceptionEnabled &&
            toolState.selectedPerception == .cvdLens &&
            toolState.selectedCVDType == type

        return Button {
            toolState.selectedCVDType = type
            toolState.selectedPerception = .cvdLens
            toolState.isPerceptionEnabled = true

            if toolState.cvdIntensity < 0.85 {
                toolState.cvdIntensity = 1.0
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.42), lineWidth: 1.2)
                        }
                }

                Text(code)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.70))
            }
            .frame(width: 42, height: 38)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }

    private func sourceButton(_ source: DesignReviewSourceKind) -> some View {
        let isSelected = designReviewState.activeSource == source

        return Button {
            switch source {
            case .demo:
                designReviewState.useDemoSource()
            case .importedImage:
                importAction()
            case .liveSurface:
                designReviewState.useLiveSample(nil)
                toolState.selectedPerception = .cvdLens
                toolState.isPerceptionEnabled = true
                toolState.filterApplicationMode = .lens
                if toolState.cvdIntensity < 0.85 {
                    toolState.cvdIntensity = 1.0
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: source.systemImage)
                    .font(.system(size: 10, weight: .semibold))

                Text(source.title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.68))
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(isSelected ? .white.opacity(0.22) : .clear, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(isSelected ? 0.42 : 0.0), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }
}

// MARK: - Contrast Checker

struct ContrastCheckerPreview: View {
    @Environment(DesignReviewState.self) private var designReviewState
    @Environment(ToolState.self) private var toolState

    private var foregroundColor: Color { Color(designReviewState.foregroundColor) }
    private var backgroundColor: Color { Color(designReviewState.backgroundColor) }

    private var foregroundBinding: Binding<Color> {
        Binding(
            get: { Color(designReviewState.foregroundColor) },
            set: { designReviewState.foregroundColor = UIColor($0) }
        )
    }

    private var backgroundBinding: Binding<Color> {
        Binding(
            get: { Color(designReviewState.backgroundColor) },
            set: { designReviewState.backgroundColor = UIColor($0) }
        )
    }

    private var analyzedForegroundColor: UIColor { analyzedColor(designReviewState.foregroundColor) }
    private var analyzedBackgroundColor: UIColor { analyzedColor(designReviewState.backgroundColor) }

    private var ratio: Double {
        ContrastAnalyzer.contrastRatio(between: analyzedForegroundColor, and: analyzedBackgroundColor)
    }

    private var rating: ContrastRating { ContrastAnalyzer.rating(for: ratio) }

    private var detectedColorPairs: [(original: NamedColorPairResult, analyzed: NamedColorPairResult)] {
        let originalTokens = sourceColorTokens
        let analyzedTokens = originalTokens.map { token in
            DesignReviewColorToken(name: token.name, color: analyzedColor(token.color), role: token.role)
        }

        return zip(
            DesignReviewState.colorPairs(from: originalTokens),
            DesignReviewState.colorPairs(from: analyzedTokens)
        ).map { (original: $0.0, analyzed: $0.1) }
    }

    private var sourceColorTokens: [DesignReviewColorToken] {
        switch designReviewState.activeSource {
        case .demo:
            return DesignReviewState.demoColorTokens
        case .importedImage, .liveSurface:
            return Array(designReviewState.activeColors.prefix(6))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label("Contrast Checker", systemImage: "checkmark.shield")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.94))
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(String(format: "%.2f:1", ratio))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(rating.color)
            }

            HStack(spacing: 14) {
                referenceColorControl(title: "Text Color", color: foregroundColor, selection: foregroundBinding, isTextTarget: true)
                    .frame(maxWidth: .infinity)

                referenceColorControl(title: "Background", color: backgroundColor, selection: backgroundBinding, isTextTarget: false)
                    .frame(maxWidth: .infinity)
            }

            if designReviewState.contrastPickTarget != nil {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap")
                        .font(.caption2)
                        .foregroundStyle(.blue)

                    Text(designReviewState.contrastPickTarget == .text ? "Tap text color in the design." : "Tap background color in the design.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Cancel") {
                        designReviewState.cancelContrastPicking()
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                }
                .padding(9)
                .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor)

                Text("Readable sample text")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            }

            HStack(spacing: 10) {
                ratingBadge(label: "Normal text", ratio: ratio, largeText: false)
                ratingBadge(label: "Large text", ratio: ratio, largeText: true)
            }

            if rating == .fail || rating == .aaLarge {
                Label("Increase contrast to at least 4.5:1 for normal text", systemImage: "lightbulb.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if !detectedColorPairs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested pairs to verify")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))

                    ForEach(Array(detectedColorPairs.prefix(3).enumerated()), id: \.element.analyzed.id) { _, pair in
                        suggestedPairRow(pair)
                    }
                }
            }
        }
        .padding(.top, 2)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func suggestedPairRow(_ pair: (original: NamedColorPairResult, analyzed: NamedColorPairResult)) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 5) {
                colorSquare(pair.analyzed.color1)
                colorSquare(pair.analyzed.color2)
            }
            .frame(width: 58, alignment: .leading)

            Text("\(pair.analyzed.hex1) / \(pair.analyzed.hex2)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 5) {
                Text(String(format: "%.1f:1", pair.analyzed.ratio))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(pair.analyzed.rating.color)

                Text(pair.analyzed.rating.label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(pair.analyzed.rating.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)

                Button("Test") {
                    designReviewState.setContrastPair(pair.original)
                }
                .font(.system(size: 9, weight: .bold))
                .buttonStyle(.plain)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.blue.opacity(0.18), in: Capsule())
            }
            .frame(width: 58, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(pair.analyzed.rating == .fail ? .red.opacity(0.075) : .white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func colorSquare(_ color: UIColor) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Color(color))
            .frame(width: 24, height: 24)
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
    }

    private func referenceColorControl(title: String, color: Color, selection: Binding<Color>, isTextTarget: Bool) -> some View {
        let isPickingThisTarget = isTextTarget
            ? designReviewState.contrastPickTarget == .text
            : designReviewState.contrastPickTarget == .background

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 6)

                ColorPicker("", selection: selection)
                    .labelsHidden()
                    .frame(width: 30, height: 30)

                Button {
                    designReviewState.beginPickingContrastColor(isTextTarget ? .text : .background)
                } label: {
                    Image(systemName: "eyedropper")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(isPickingThisTarget ? .blue.opacity(0.85) : .white.opacity(0.10), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(isPickingThisTarget ? .white.opacity(0.75) : .white.opacity(0.18), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(height: 34)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func ratingBadge(label: String, ratio: Double, largeText: Bool) -> some View {
        let badgeRating = ContrastAnalyzer.rating(for: ratio, largeText: largeText)

        return VStack(spacing: 4) {
            Text(badgeRating.label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(badgeRating.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(badgeRating.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func analyzedColor(_ color: UIColor) -> UIColor {
        guard toolState.isPerceptionEnabled,
              toolState.selectedPerception == .cvdLens else {
            return color
        }

        let simulatedColor = ColorBlindnessSimulator.simulate(color, cvdType: toolState.selectedCVDType)
        return color.interpolate(to: simulatedColor, amount: toolState.cvdIntensity)
    }
}

// MARK: - Scan Preview

struct ColorScanPreview: View {
    @Environment(DesignReviewState.self) private var designReviewState
    @Environment(ToolState.self) private var toolState

    private var analyzedColorTokens: [DesignReviewColorToken] {
        guard toolState.isPerceptionEnabled,
              toolState.selectedPerception == .cvdLens else {
            return designReviewState.activeColors
        }

        return designReviewState.activeColors.map { token in
            let simulatedColor = ColorBlindnessSimulator.simulate(token.color, cvdType: toolState.selectedCVDType)
            let blendedColor = token.color.interpolate(to: simulatedColor, amount: toolState.cvdIntensity)
            return DesignReviewColorToken(name: token.name, color: blendedColor, role: token.role)
        }
    }

    private var riskiestPair: NamedColorPairResult? {
        DesignReviewState.colorPairs(from: analyzedColorTokens).first
    }

    private var isFilterActive: Bool {
        toolState.isPerceptionEnabled && toolState.selectedPerception == .cvdLens
    }

    private var activeFilterName: String {
        guard isFilterActive else { return "Original" }
        switch toolState.selectedCVDType {
        case .protanopia: return "P · Protanopia"
        case .deuteranopia: return "D · Deuteranopia"
        case .tritanopia: return "T · Tritanopia"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: isFilterActive ? "eye" : "eye.slash")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(isFilterActive ? "Scanning simulated colors" : "Scanning original colors")
                        .font(.caption2)
                        .fontWeight(.bold)

                    Text("\(activeFilterName) · Intensity \(Int(toolState.cvdIntensity * 100))%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(10)
            .background(.white.opacity(0.085), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            if let riskiestPair {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Riskiest pair")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("\(riskiestPair.firstName) ↔ \(riskiestPair.secondName)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(String(format: "%.2f:1", riskiestPair.ratio))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(riskiestPair.rating.color)

                        Text(riskiestPair.rating.label)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(riskiestPair.rating.color)
                    }
                }

                HStack(spacing: 10) {
                    colorChip(color: riskiestPair.color1, label: riskiestPair.hex1)
                    Image(systemName: "arrow.left.and.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    colorChip(color: riskiestPair.color2, label: riskiestPair.hex2)
                }

                InlineContrastResult(pair: riskiestPair)

                Text(scanSuggestion(for: riskiestPair.rating))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    designReviewState.setContrastPair(riskiestPair)
                } label: {
                    Label("Check this pair", systemImage: "checkmark.shield")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.10), in: Capsule())
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
            } else {
                Text("No color pairs found yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func colorChip(color: UIColor, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(color))
                .frame(width: 26, height: 26)
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }

            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func scanSuggestion(for rating: ContrastRating) -> String {
        switch rating {
        case .aaa, .aa:
            return "This pair passes for normal text. Keep checking critical UI states."
        case .aaLarge:
            return "Use this pair only for large text, or increase contrast for smaller labels."
        case .fail:
            return "Increase contrast or add symbols/borders so meaning is not carried by color alone."
        }
    }
}

struct InlineContrastResult: View {
    let pair: NamedColorPairResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Readable preview", systemImage: "checkmark.shield")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(pair.rating.color)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(pair.color2))

                Text("Readable sample text")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(pair.color1))
            }
            .frame(height: 46)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
        }
        .padding(12)
        .background(.black.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: 0...1)
        }
    }
}

// MARK: - Sample Design Canvas

struct SampleDesignCanvas: View {
    @Environment(ToolState.self) private var toolState
    @Environment(DesignReviewState.self) private var designReviewState
    let importAction: () -> Void
    @State private var lensOffset: CGSize = .zero
    @State private var lensDragStartOffset: CGSize?

    private let importedLensSize: CGFloat = 168
    private let importedImagePadding: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            switch designReviewState.activeSource {
            case .demo:
                demoContent
            case .importedImage:
                importDesignContent
            case .liveSurface:
                EmptyView()
            }
        }
        .padding(36)
        .frame(width: 1160)
        .background(.white.opacity(0.115), in: RoundedRectangle(cornerRadius: 42, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .stroke(.white.opacity(toolState.strongBordersEnabled ? 0.55 : 0.20), lineWidth: toolState.strongBordersEnabled ? 3 : 1)
        }
        .brightness(Double(toolState.isToolEnabled ? (toolState.brightnessIntensity - 0.30) * 0.45 : 0))
        .contrast(Double(toolState.isToolEnabled ? (0.75 + toolState.contrastIntensity * 1.15) : 1))
        .saturation(perceptionSaturation)
        .overlay { perceptionOverlay }
        .overlay(alignment: .top) {
            if shouldShowDemoPickingHint {
                demoPickingHint
                    .offset(y: -58)
                    .zIndex(80)
            }
        }
        .overlay {
            if shouldShowDemoLensHint {
                GeometryReader { proxy in
                    demoLensPreview(viewSize: proxy.size)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        .offset(lensOffset)
                        .zIndex(30)
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    if shouldShowDemoPickingHint {
                        pickDemoContrastColor(at: value.location)
                    }
                }
        )
        .glassBackgroundEffect()
    }

    private var demoContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 22) {
                statusCard(title: "Approved", subtitle: "Color + symbol", color: perceivedColor(.green), symbol: "checkmark.circle.fill")
                statusCard(title: "Warning", subtitle: "Needs attention", color: perceivedColor(.orange), symbol: "exclamationmark.triangle.fill")
                statusCard(title: "Error", subtitle: "Action required", color: perceivedColor(.red), symbol: "xmark.circle.fill")
            }

            HStack(spacing: 24) {
                chartPreview
                formPreview
            }
        }
    }

    private var importDesignContent: some View {
        VStack(spacing: 20) {
            if let importedImage = designReviewState.importedImage {
                GeometryReader { proxy in
                    ZStack {
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .fill(.regularMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 40, style: .continuous)
                                    .fill(.white.opacity(0.055))
                            }

                        Image(uiImage: fullWorldFilteredImage(from: importedImage))
                            .resizable()
                            .scaledToFit()
                            .padding(24)
                            .frame(width: proxy.size.width, height: proxy.size.height)

                        if isInspectionLensActive, designReviewState.contrastPickTarget == nil {
                            importedLensPreview(image: importedImage, viewSize: proxy.size)
                                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                                .offset(lensOffset)
                                .zIndex(20)
                        }

                        if let pickTarget = designReviewState.contrastPickTarget {
                            VStack(spacing: 8) {
                                Image(systemName: "eyedropper")
                                    .font(.headline)

                                Text(pickTarget == .text ? "Tap text color" : "Tap background color")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(.black.opacity(0.55), in: Capsule())
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 12)
                            .allowsHitTesting(false)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .stroke(.white.opacity(toolState.strongBordersEnabled ? 0.44 : 0.14), lineWidth: toolState.strongBordersEnabled ? 2.4 : 1)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                if designReviewState.contrastPickTarget != nil {
                                    pickImportedImageColor(from: importedImage, at: value.location, in: proxy.size)
                                }
                            }
                    )
                }
                .frame(maxWidth: .infinity)
                .frame(height: 500)

                importedTokensStrip
            } else if !designReviewState.importedColorTokens.isEmpty {
                importedTokensSurface
            } else {
                EmptyView()
            }
        }
    }

    private var isInspectionLensActive: Bool {
        toolState.isPerceptionEnabled &&
        toolState.selectedPerception == .cvdLens &&
        toolState.filterApplicationMode == .lens &&
        designReviewState.importedImage != nil
    }

    private var lensLabelTitle: String {
        switch toolState.selectedCVDType {
        case .protanopia: return "P Lens"
        case .deuteranopia: return "D Lens"
        case .tritanopia: return "T Lens"
        }
    }

    private func importedLensPreview(image: UIImage, viewSize: CGSize) -> some View {
        let simulatedImage = teammateLensSimulation(from: image)

        return ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.11))

                Image(uiImage: simulatedImage)
                    .resizable()
                    .scaledToFit()
                    .padding(importedImagePadding)
                    .frame(width: viewSize.width, height: viewSize.height)
            }
            .frame(width: viewSize.width, height: viewSize.height)
            .offset(x: -lensOffset.width, y: -lensOffset.height)
            .mask(
                RoundedRectangle(cornerRadius: 36)
                    .frame(width: importedLensSize, height: importedLensSize)
            )

            RoundedRectangle(cornerRadius: 36)
                .strokeBorder(.white.opacity(0.9), lineWidth: 4)
                .frame(width: importedLensSize, height: importedLensSize)
                .shadow(color: .white.opacity(0.35), radius: 12)

            VStack(spacing: 4) {
                Image(systemName: "eye")
                    .font(.title3)

                Text(lensLabelTitle)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.black.opacity(0.5), in: Capsule())
            .offset(y: -(importedLensSize / 2) - 22)
        }
        .frame(width: importedLensSize, height: importedLensSize)
        .contentShape(RoundedRectangle(cornerRadius: 36))
        .gesture(lensDragGesture(in: viewSize))
    }

    private func teammateLensSimulation(from image: UIImage) -> UIImage {
        if toolState.selectedCVDType != .deuteranopia {
            return ColorBlindnessSimulator.simulate(
                image,
                cvdType: toolState.selectedCVDType
            )
        }

        guard let inputCIImage = CIImage(image: image) else { return image }
        let filter = CIFilter.colorMatrix()
        filter.inputImage = inputCIImage
        filter.rVector = CIVector(x: 0.367322, y: 0.860646, z: -0.227968, w: 0.0)
        filter.gVector = CIVector(x: 0.280085, y: 0.672501, z: 0.047413, w: 0.0)
        filter.bVector = CIVector(x: -0.011820, y: 0.042940, z: 0.968881, w: 0.0)
        filter.aVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0)

        guard let outputImage = filter.outputImage else { return image }
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: inputCIImage.extent) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func demoLensPreview(viewSize: CGSize) -> some View {
        ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.11))

                demoLensFilteredCanvas
                    .frame(width: viewSize.width, height: viewSize.height, alignment: .topLeading)
            }
            .frame(width: viewSize.width, height: viewSize.height)
            .offset(x: -lensOffset.width, y: -lensOffset.height)
            .mask(
                RoundedRectangle(cornerRadius: 36)
                    .frame(width: importedLensSize, height: importedLensSize)
            )

            RoundedRectangle(cornerRadius: 36)
                .strokeBorder(.white.opacity(0.9), lineWidth: 4)
                .frame(width: importedLensSize, height: importedLensSize)
                .shadow(color: .white.opacity(0.35), radius: 12)

            Text(lensLabelTitle)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.black.opacity(0.5), in: Capsule())
                .offset(y: -(importedLensSize / 2) - 22)
        }
        .frame(width: importedLensSize, height: importedLensSize)
        .contentShape(RoundedRectangle(cornerRadius: 36))
        .gesture(lensDragGesture(in: viewSize))
    }

    private func lensDragGesture(in viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if lensDragStartOffset == nil {
                    lensDragStartOffset = lensOffset
                }

                let startOffset = lensDragStartOffset ?? lensOffset
                let proposedOffset = CGSize(
                    width: startOffset.width + value.translation.width,
                    height: startOffset.height + value.translation.height
                )

                lensOffset = limitedLensOffset(proposedOffset, in: viewSize)
            }
            .onEnded { _ in
                lensDragStartOffset = nil
            }
    }

    private func fullWorldFilteredImage(from image: UIImage) -> UIImage {
        guard toolState.isPerceptionEnabled,
              toolState.selectedPerception == .cvdLens,
              toolState.filterApplicationMode == .fullWorld else {
            return image
        }

        return ColorBlindnessSimulator.simulate(image, cvdType: toolState.selectedCVDType)
    }

    private func limitedLensOffset(_ translation: CGSize, in viewSize: CGSize) -> CGSize {
        let maxX = max((viewSize.width - importedLensSize) / 2, 0)
        let maxY = max((viewSize.height - importedLensSize) / 2, 0)

        return CGSize(
            width: min(max(translation.width, -maxX), maxX),
            height: min(max(translation.height, -maxY), maxY)
        )
    }

    private func pickImportedImageColor(from image: UIImage, at point: CGPoint, in viewSize: CGSize) {
        guard designReviewState.contrastPickTarget != nil,
              let color = pixelColor(in: image, at: point, in: viewSize) else {
            return
        }

        designReviewState.applyPickedContrastColor(color, at: point)
    }

    private func pixelColor(in image: UIImage, at point: CGPoint, in viewSize: CGSize) -> UIColor? {
        guard let cgImage = image.cgImage else { return nil }

        let imagePixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let imageAspect = imagePixelSize.width / imagePixelSize.height
        let viewAspect = viewSize.width / viewSize.height

        let displayedSize: CGSize
        if imageAspect > viewAspect {
            displayedSize = CGSize(width: viewSize.width, height: viewSize.width / imageAspect)
        } else {
            displayedSize = CGSize(width: viewSize.height * imageAspect, height: viewSize.height)
        }

        let origin = CGPoint(
            x: (viewSize.width - displayedSize.width) / 2,
            y: (viewSize.height - displayedSize.height) / 2
        )

        guard point.x >= origin.x,
              point.y >= origin.y,
              point.x <= origin.x + displayedSize.width,
              point.y <= origin.y + displayedSize.height else {
            return nil
        }

        let relativeX = (point.x - origin.x) / displayedSize.width
        let relativeY = (point.y - origin.y) / displayedSize.height
        let pixelX = min(max(Int(relativeX * imagePixelSize.width), 0), cgImage.width - 1)
        let pixelY = min(max(Int(relativeY * imagePixelSize.height), 0), cgImage.height - 1)

        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return nil
        }

        let bytesPerPixel = max(cgImage.bitsPerPixel / 8, 4)
        let bytesPerRow = cgImage.bytesPerRow
        let offset = pixelY * bytesPerRow + pixelX * bytesPerPixel

        guard offset + 2 < CFDataGetLength(data) else { return nil }

        let bitmapInfo = cgImage.bitmapInfo
        let alphaInfo = CGImageAlphaInfo(rawValue: bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        let byteOrder = bitmapInfo.intersection(.byteOrderMask)

        let red: UInt8
        let green: UInt8
        let blue: UInt8

        if byteOrder == .byteOrder32Little {
            blue = bytes[offset]
            green = bytes[offset + 1]
            red = bytes[offset + 2]
        } else if alphaInfo == .premultipliedLast || alphaInfo == .last || alphaInfo == .noneSkipLast {
            red = bytes[offset]
            green = bytes[offset + 1]
            blue = bytes[offset + 2]
        } else {
            blue = bytes[offset]
            green = bytes[offset + 1]
            red = bytes[offset + 2]
        }

        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    private var importedTokensSurface: some View {
        VStack(alignment: .leading, spacing: 16) {
            importedTokensHeader
            importedTokensGrid
        }
        .padding(18)
        .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var importedTokensStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            importedTokensHeader
            importedTokensGrid
        }
        .padding(18)
        .background(.black.opacity(0.085), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var importedTokensHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.11), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(importedDisplayName(for: designReviewState.importedSourceName))
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(designReviewState.importedColorTokens.count) extracted colors for Lens and Contrast tools.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var importedTokensGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            ForEach(designReviewState.importedColorTokens) { token in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(token.color))
                        .frame(height: 46)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(importedTokenDisplayName(token.name))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Text(token.color.hexString)
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    private enum SemanticColor { case blue, green, orange, red }

    private func normalRGB(_ color: SemanticColor) -> (red: Double, green: Double, blue: Double) {
        switch color {
        case .blue: return (0.00, 0.48, 1.00)
        case .green: return (0.20, 0.78, 0.35)
        case .orange: return (1.00, 0.58, 0.00)
        case .red: return (1.00, 0.23, 0.19)
        }
    }

    private func perceivedColor(_ color: SemanticColor) -> Color {
        let rgb = normalRGB(color)
        let original = UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1.0)

        guard toolState.isPerceptionEnabled,
              toolState.selectedPerception == .cvdLens,
              toolState.filterApplicationMode == .fullWorld else {
            return Color(original)
        }

        let simulated = ColorBlindnessSimulator.simulate(original, cvdType: toolState.selectedCVDType)
        return Color(original.interpolate(to: simulated, amount: toolState.cvdIntensity))
    }

    private var shouldShowDemoPickingHint: Bool {
        designReviewState.activeSource == .demo && designReviewState.contrastPickTarget != nil
    }

    private var demoPickingHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "eyedropper")
                .font(.system(size: 13, weight: .bold))

            Text(designReviewState.contrastPickTarget == .text ? "Tap a colored symbol, bar, or text in the demo" : "Tap a demo background or UI color")
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)

            Button("Cancel") {
                designReviewState.cancelContrastPicking()
            }
            .font(.system(size: 11, weight: .bold))
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.16), in: Capsule())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.black.opacity(0.82), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.32), lineWidth: 1)
        }
    }

    private func pickDemoContrastColor(at point: CGPoint) {
        guard designReviewState.contrastPickTarget != nil else { return }
        let pickedColor = demoColor(at: point, isTextTarget: designReviewState.contrastPickTarget == .text)
        designReviewState.applyPickedContrastColor(pickedColor, at: point)
    }

    private func demoColor(at point: CGPoint, isTextTarget: Bool) -> UIColor {
        let x = point.x
        let y = point.y

        if isTextTarget { return demoTextOrSymbolColor(at: point) }

        if y < 230 {
            if x < 390 { return uiColor(for: .green) }
            if x < 770 { return uiColor(for: .orange) }
            return uiColor(for: .red)
        }

        if x < 290 { return uiColor(for: .blue) }
        if x < 510 { return uiColor(for: .green) }
        if x < 720 { return uiColor(for: .orange) }
        if x < 870 { return uiColor(for: .red) }
        return UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)
    }

    private func demoTextOrSymbolColor(at point: CGPoint) -> UIColor {
        let x = point.x
        let y = point.y

        if y < 230 {
            if x < 390 { return uiColor(for: .green) }
            if x < 770 { return uiColor(for: .orange) }
            return uiColor(for: .red)
        }

        if y >= 250 && y < 610 && x < 760 {
            if x < 290 { return uiColor(for: .blue) }
            if x < 510 { return uiColor(for: .green) }
            if x < 720 { return uiColor(for: .orange) }
            return uiColor(for: .red)
        }

        if x >= 760 {
            if y < 360 { return uiColor(for: .blue) }
            if y < 460 { return uiColor(for: .green) }
            if y < 570 { return uiColor(for: .red) }
        }

        return UIColor(white: 0.92, alpha: 1.0)
    }

    private func uiColor(for semanticColor: SemanticColor) -> UIColor {
        let rgb = normalRGB(semanticColor)
        return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1.0)
    }

    private var shouldShowDemoLensHint: Bool {
        designReviewState.activeSource == .demo &&
        toolState.isPerceptionEnabled &&
        toolState.selectedPerception == .cvdLens &&
        toolState.filterApplicationMode == .lens
    }

    private var demoLensFilteredCanvas: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            demoLensFilteredContent
        }
        .padding(36)
        .frame(width: 1160, alignment: .topLeading)
        .background(.white.opacity(0.115), in: RoundedRectangle(cornerRadius: 42, style: .continuous))
    }

    private var demoLensFilteredContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 22) {
                statusCard(title: "Approved", subtitle: "Color + symbol", color: demoLensFilteredColor(.green), symbol: "checkmark.circle.fill")
                statusCard(title: "Warning", subtitle: "Needs attention", color: demoLensFilteredColor(.orange), symbol: "exclamationmark.triangle.fill")
                statusCard(title: "Error", subtitle: "Action required", color: demoLensFilteredColor(.red), symbol: "xmark.circle.fill")
            }

            HStack(spacing: 24) {
                demoLensChartPreview
                demoLensFormPreview
            }
        }
    }

    private var demoLensChartPreview: some View {
        chartSection(useLensColors: true)
    }

    private var demoLensFormPreview: some View {
        formSection(useLensColors: true)
    }

    private func demoLensFilteredColor(_ color: SemanticColor) -> Color {
        let rgb = normalRGB(color)
        let original = UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1.0)
        let simulated = ColorBlindnessSimulator.simulate(original, cvdType: toolState.selectedCVDType)
        return Color(original.interpolate(to: simulated, amount: toolState.cvdIntensity))
    }

    private var perceptionSaturation: Double {
        guard toolState.isPerceptionEnabled,
              toolState.selectedPerception == .cvdLens,
              toolState.filterApplicationMode == .fullWorld else {
            return 1.0
        }

        return 1.0 - toolState.cvdIntensity * 0.18
    }

    @ViewBuilder
    private var perceptionOverlay: some View {
        if toolState.isPerceptionEnabled,
           toolState.selectedPerception == .cvdLens,
           toolState.filterApplicationMode == .fullWorld {
            ZStack {
                Rectangle()
                    .fill(cvdTintColor)
                    .opacity(0.03 + toolState.cvdIntensity * 0.08)
                    .blendMode(.softLight)

                Rectangle()
                    .fill(.gray.opacity(0.02 + toolState.cvdIntensity * 0.04))
                    .blendMode(.saturation)
            }
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
    }

    private var cvdTintColor: Color {
        switch toolState.selectedCVDType {
        case .protanopia: return Color(red: 0.78, green: 0.66, blue: 0.32)
        case .deuteranopia: return Color(red: 0.70, green: 0.64, blue: 0.30)
        case .tritanopia: return Color(red: 0.40, green: 0.56, blue: 0.74)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(designReviewState.activeSource == .importedImage ? "Imported Design Review" : "Sample Accessibility Test")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(designReviewState.activeSource == .importedImage ? "Inspect the selected design with Lens and verify colors with Contrast." : "Import a design, inspect it with Lens, and verify readability with Contrast.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if designReviewState.activeSource == .importedImage,
               designReviewState.importedImage != nil || !designReviewState.importedColorTokens.isEmpty {
                Button {
                    designReviewState.clearImportedDesign()
                    designReviewState.activeSource = .importedImage
                    importAction()
                } label: {
                    Label("Replace image", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.86))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.11), in: Capsule())
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
            }
        }
    }

    private func statusCard(title: String, subtitle: String, color: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 22, height: 22)

                if toolState.symbolsEnabled {
                    Image(systemName: symbol)
                        .foregroundStyle(color)
                        .font(.headline)
                }

                Spacer()
            }

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(toolState.strongBordersEnabled ? 0.55 : 0.11), lineWidth: toolState.strongBordersEnabled ? 2.5 : 1)
        }
    }

    private var chartPreview: some View { chartSection(useLensColors: false) }
    private var formPreview: some View { formSection(useLensColors: false) }

    private func chartSection(useLensColors: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Color-coded chart")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(alignment: .bottom, spacing: 18) {
                chartBar(height: 122, color: useLensColors ? demoLensFilteredColor(.blue) : perceivedColor(.blue), label: "A")
                chartBar(height: 170, color: useLensColors ? demoLensFilteredColor(.green) : perceivedColor(.green), label: "B")
                chartBar(height: 98, color: useLensColors ? demoLensFilteredColor(.orange) : perceivedColor(.orange), label: "C")
                chartBar(height: 145, color: useLensColors ? demoLensFilteredColor(.red) : perceivedColor(.red), label: "D")
            }
            .frame(height: 196, alignment: .bottom)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func chartBar(height: CGFloat, color: Color, label: String) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 54, height: height)
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

    private func formSection(useLensColors: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Form readability")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 10) {
                fieldRow(title: "Primary action", color: useLensColors ? demoLensFilteredColor(.blue) : perceivedColor(.blue), icon: "arrow.right.circle.fill")
                fieldRow(title: "Success message", color: useLensColors ? demoLensFilteredColor(.green) : perceivedColor(.green), icon: "checkmark.circle.fill")
                fieldRow(title: "Error message", color: useLensColors ? demoLensFilteredColor(.red) : perceivedColor(.red), icon: "xmark.octagon.fill")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func fieldRow(title: String, color: Color, icon: String) -> some View {
        HStack(spacing: 10) {
            if toolState.symbolsEnabled {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 58, height: 16)
        }
        .padding(15)
        .background(.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Full Scene Filter and Adjustment Overlays

struct FullSceneFilterOverlay: View {
    @Environment(ToolState.self) private var toolState
    @Environment(DesignReviewState.self) private var designReviewState

    var body: some View {
        if designReviewState.activeSource != .liveSurface &&
            toolState.selectedPerception == .cvdLens &&
            toolState.isPerceptionEnabled &&
            toolState.filterApplicationMode == .fullWorld {
            ZStack {
                Rectangle()
                    .fill(overlayColor)
                    .opacity(overlayOpacity)
                    .ignoresSafeArea()

                Rectangle()
                    .fill(.gray.opacity(0.08 + toolState.cvdIntensity * 0.24))
                    .blendMode(.saturation)
                    .opacity(0.34 + toolState.cvdIntensity * 0.36)
            }
            .frame(width: 12000, height: 8000)
            .contentShape(Rectangle())
            .allowsHitTesting(false)
        }
    }

    private var overlayColor: Color {
        switch toolState.selectedCVDType {
        case .protanopia: return Color(red: 0.72, green: 0.62, blue: 0.34)
        case .deuteranopia: return Color(red: 0.68, green: 0.62, blue: 0.32)
        case .tritanopia: return Color(red: 0.42, green: 0.56, blue: 0.72)
        }
    }

    private var overlayOpacity: Double {
        0.08 + toolState.cvdIntensity * 0.26
    }
}

struct AdjustmentToolsOverlay: View {
    @Environment(ToolState.self) private var toolState

    var body: some View {
        ZStack {
            brightnessLayer
            contrastLayer

            if toolState.strongBordersEnabled {
                strongBordersLayer
            }
        }
        .frame(width: 12000, height: 8000)
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
                    .frame(width: CGFloat(900 + index * 360), height: CGFloat(560 + index * 230))
                    .opacity(index.isMultiple(of: 2) ? 0.40 : 0.24)
            }

            Rectangle()
                .strokeBorder(.white.opacity(0.16), lineWidth: 12)
        }
        .blendMode(.screen)
    }
}

// MARK: - Fingertip Button

struct FingertipToolButton: View {
    let tool: HandTrackingModel.FingertipTool
    let isSelected: Bool
    let isPressed: Bool
    let action: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: isSelected || isPressed ? 35 : 31, height: isSelected || isPressed ? 35 : 31)
                .overlay {
                    Circle()
                        .strokeBorder(strokeColor, lineWidth: isSelected || isPressed ? 1.7 : 0.8)
                }
                .shadow(color: glowColor, radius: isSelected || isPressed ? 6 : 0)

            Image(systemName: tool.systemImage)
                .font(.system(size: isSelected || isPressed ? 16 : 14.5, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(isSelected || isPressed ? 1.0 : 0.90))
        }
        .frame(width: 38, height: 38)
        .contentShape(Circle())
        .background(Color.clear)
        .clipShape(Circle())
        .scaleEffect(isPressed ? 0.92 : (isSelected ? 1.03 : 1.0))
        .animation(.spring(response: 0.18, dampingFraction: 0.80), value: isSelected)
        .animation(.spring(response: 0.12, dampingFraction: 0.76), value: isPressed)
        .onTapGesture { action() }
    }

    private var fillColor: Color {
        if isPressed { return Color(red: 0.00, green: 0.58, blue: 1.00).opacity(0.30) }
        if isSelected { return Color(red: 0.35, green: 0.78, blue: 1.00).opacity(0.14) }
        return Color.white.opacity(0.025)
    }

    private var strokeColor: Color {
        if isPressed { return Color(red: 0.10, green: 0.78, blue: 1.00).opacity(0.96) }
        if isSelected { return Color(red: 0.35, green: 0.78, blue: 1.00).opacity(0.82) }
        return Color.white.opacity(0.18)
    }

    private var glowColor: Color {
        if isPressed { return Color(red: 0.00, green: 0.60, blue: 1.00).opacity(0.20) }
        if isSelected { return Color(red: 0.35, green: 0.78, blue: 1.00).opacity(0.08) }
        return Color.clear
    }
}

// MARK: - Tool Panels

struct AdjustToolPanel: View {
    @Bindable var toolState: ToolState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Visibility adjustments", systemImage: "slider.horizontal.3")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("Tune brightness, contrast, borders, and symbols on the active review surface.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Divider().opacity(0.22)

                SliderRow(title: "Brightness", value: $toolState.brightnessIntensity)
                SliderRow(title: "Contrast", value: $toolState.contrastIntensity)
            }
            .padding(14)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                Label("Support cues", systemImage: "wand.and.stars")
                    .font(.caption)
                    .fontWeight(.semibold)

                Toggle("Symbols with color", isOn: $toolState.symbolsEnabled)
                Toggle("Stronger borders", isOn: $toolState.strongBordersEnabled)
            }
            .padding(14)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct LensToolPanel: View {
    @Bindable var toolState: ToolState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "circle.dashed")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Inspection lens")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Text("The filter starts on the whole world. Switch here to inspect with a moving lens.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .opacity(0.22)

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Filter")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(lensStatusTitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary.opacity(0.86))
                    }

                    Spacer()

                    Toggle("", isOn: lensToggleBinding)
                        .labelsHidden()
                }

                HStack(spacing: 8) {
                    filterModeButton(.fullWorld)
                    filterModeButton(.lens)
                }

                SliderRow(title: "Filter intensity", value: $toolState.cvdIntensity)
            }
        }
    }

    private var lensStatusTitle: String {
        guard lensToggleBinding.wrappedValue else {
            return "Off"
        }

        return toolState.filterApplicationMode.title
    }

    private func filterModeButton(_ mode: ToolState.FilterApplicationMode) -> some View {
        let isSelected = toolState.filterApplicationMode == mode

        return Button {
            toolState.filterApplicationMode = mode
            toolState.selectedPerception = .cvdLens
            toolState.isPerceptionEnabled = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 10, weight: .semibold))

                Text(mode.shortTitle)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.66))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? .white.opacity(0.18) : .white.opacity(0.07), in: Capsule())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }

    private var lensToggleBinding: Binding<Bool> {
        Binding(
            get: { toolState.isPerceptionEnabled && toolState.selectedPerception == .cvdLens },
            set: { isEnabled in
                toolState.isPerceptionEnabled = isEnabled
                if isEnabled { toolState.selectedPerception = .cvdLens }
            }
        )
    }
}

struct ScanToolPanel: View {
    @Bindable var toolState: ToolState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Automatic scan", systemImage: "scope")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("Find the riskiest pair using the current P / D / T filter and intensity.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ColorScanPreview()
            }
            .padding(14)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct ContrastToolPanel: View {
    @Bindable var toolState: ToolState
    let closeAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ContrastCheckerPreview()
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 20)

            Button(action: closeAction) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.96))
                    .frame(width: 24, height: 24)
                    .background(.black.opacity(0.20), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.28), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .hoverEffect(.highlight)
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
    }
}

// MARK: - Helpers

func importedDisplayName(for importedSourceName: String) -> String {
    let sourceName = importedSourceName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !sourceName.isEmpty else { return "Imported Design" }

    let looksLikeHash = sourceName.range(
        of: "^[A-Fa-f0-9]{20,}$",
        options: .regularExpression
    ) != nil

    if sourceName.count > 28 || looksLikeHash {
        return "Imported Design"
    }

    return sourceName
}

func importedTokenDisplayName(_ name: String) -> String {
    let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

    if let colorRange = cleanedName.range(of: " color ", options: .caseInsensitive) {
        let suffix = cleanedName[colorRange.upperBound...]
        return "Color \(suffix)"
    }

    if cleanedName.count > 18 {
        return "Color"
    }

    return cleanedName.isEmpty ? "Color" : cleanedName
}
