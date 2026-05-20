//
//  ToolState.swift
//  ToolsOfSighted
//
//  Created by Layan Albarrak on 20/05/2026.
//

import SwiftUI

enum SightTool: String, CaseIterable, Identifiable {
    case cvdLens = "CVD Lens"
    case lowVision = "Low Vision"
    case dyslexia = "Dyslexia"
    case contrast = "Contrast"
    case blur = "Blur"

    var id: String {
        rawValue
    }

    var iconName: String {
        switch self {
        case .cvdLens:
            return "eye"
        case .lowVision:
            return "eye.trianglebadge.exclamationmark"
        case .dyslexia:
            return "textformat"
        case .contrast:
            return "circle.lefthalf.filled"
        case .blur:
            return "camera.filters"
        }
    }

    var shortDescription: String {
        switch self {
        case .cvdLens:
            return "Color blindness simulation"
        case .lowVision:
            return "Reduced clarity simulation"
        case .dyslexia:
            return "Reading difficulty simulation"
        case .contrast:
            return "Contrast accessibility test"
        case .blur:
            return "Blurred vision simulation"
        }
    }
}

@Observable
final class ToolState {
    var selectedTool: SightTool? = .cvdLens

    var selectedPerception: SightTool? = nil
    var isPerceptionEnabled: Bool = true

    var isToolEnabled: Bool = true

    var cvdIntensity: Double = 0.75
    var selectedCVDType: CVDType = .deuteranopia

    var lowVisionIntensity: Double = 0.55
    var dyslexiaIntensity: Double = 0.45
    var contrastIntensity: Double = 0.60
    var blurIntensity: Double = 0.40

    enum CVDType: String, CaseIterable, Identifiable {
        case protanopia = "Protanopia"
        case deuteranopia = "Deuteranopia"
        case tritanopia = "Tritanopia"

        var id: String {
            rawValue
        }
    }
}
