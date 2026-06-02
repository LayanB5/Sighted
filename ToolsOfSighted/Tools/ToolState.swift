//
//  ToolState.swift
//  ToolsOfSighted
//
//  Created by Layan Albarrak on 20/05/2026.
//

import SwiftUI

enum SightTool: String, CaseIterable, Identifiable {
    case cvdLens = "Color Blindness"

    var id: String {
        rawValue
    }

    var iconName: String {
        switch self {
        case .cvdLens:
            return "eye"
        }
    }

    var shortDescription: String {
        switch self {
        case .cvdLens:
            return "Color blindness simulation"
        }
    }
}

@Observable
final class ToolState {
    var selectedPerception: SightTool? = nil
    var isPerceptionEnabled: Bool = false

    var isToolEnabled: Bool = false
    var selectedAdjustmentTool: AdjustmentTool? = nil
    var brightnessIntensity: Double = 0.30
    var contrastIntensity: Double = 0.60
    var strongBordersEnabled: Bool = false
    var symbolsEnabled: Bool = true

    var cvdIntensity: Double = 0.75
    var selectedCVDType: CVDType = .deuteranopia
    var filterApplicationMode: FilterApplicationMode = .fullWorld

    enum CVDType: String, CaseIterable, Identifiable {
        case protanopia = "Protanopia · Red-blind"
        case deuteranopia = "Deuteranopia · Green-blind"
        case tritanopia = "Tritanopia · Blue-yellow"

        var id: String {
            rawValue
        }
    }

    enum FilterApplicationMode: String, CaseIterable, Identifiable {
        case fullWorld
        case lens

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .fullWorld:
                return "Full world"
            case .lens:
                return "Moving lens"
            }
        }

        var shortTitle: String {
            switch self {
            case .fullWorld:
                return "Full"
            case .lens:
                return "Lens"
            }
        }

        var systemImage: String {
            switch self {
            case .fullWorld:
                return "rectangle.inset.filled"
            case .lens:
                return "circle.dashed"
            }
        }
    }

    enum AdjustmentTool: String, CaseIterable, Identifiable {
        case simulatorControls = "simulatorControls"
        case contrast = "contrast"
        case borders = "borders"
        case symbols = "symbols"

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .simulatorControls, .contrast:
                return "Contrast"
            case .borders, .symbols:
                return "Lens"
            }
        }

        var iconName: String {
            switch self {
            case .simulatorControls:
                return "checkmark.shield"
            case .contrast:
                return "checkmark.shield"
            case .borders:
                return "circle.dashed"
            case .symbols:
                return "circle.dashed"
            }
        }

        var shortDescription: String {
            switch self {
            case .simulatorControls:
                return "Check text and background readability"
            case .contrast:
                return "Check text and background readability"
            case .borders:
                return "Inspect a focused area"
            case .symbols:
                return "Inspect a focused area"
            }
        }
    }
}
