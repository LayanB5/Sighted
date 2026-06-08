//
//  DesignReviewState.swift
//  ToolsOfSighted
//
//  Created by Layan Albarrak on 01/06/2026.
//
//  Central state for the Sighted design review workflow.
//  Keeps Demo, Import, and Live source state in one place.
//

import SwiftUI
import UIKit
import Observation

// MARK: - Design Source

enum DesignReviewSourceKind: String, CaseIterable, Identifiable {
    case demo
    case importedImage
    case liveSurface

    var id: String { rawValue }

    var title: String {
        switch self {
        case .demo:
            return "Demo"
        case .importedImage:
            return "Import"
        case .liveSurface:
            return "Live"
        }
    }

    var subtitle: String {
        switch self {
        case .demo:
            return "Curated sample for presentations"
        case .importedImage:
            return "User-provided design screenshot"
        case .liveSurface:
            return "Reality or active surface review"
        }
    }

    var systemImage: String {
        switch self {
        case .demo:
            return "wand.and.stars"
        case .importedImage:
            return "photo.on.rectangle"
        case .liveSurface:
            return "visionpro"
        }
    }
}

struct DesignReviewColorToken: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: UIColor
    let role: String

    var hex: String { color.hexString }
}

struct NamedColorPairResult: Identifiable {
    let id = UUID()
    let firstName: String
    let secondName: String
    let color1: UIColor
    let color2: UIColor
    let ratio: Double
    let rating: ContrastRating

    var hex1: String { color1.hexString }
    var hex2: String { color2.hexString }
}

struct TeamImportedDesignPayload {
    let image: UIImage?
    let colorTokens: [DesignReviewColorToken]
    let sourceName: String

    init(
        image: UIImage? = nil,
        colorTokens: [DesignReviewColorToken] = [],
        sourceName: String = "Imported"
    ) {
        self.image = image
        self.colorTokens = colorTokens
        self.sourceName = sourceName
    }
}

enum SightedContrastPickTarget {
    case text
    case background
}

// MARK: - Design Review State

@Observable
final class DesignReviewState {
    var activeSource: DesignReviewSourceKind = .demo
    var importedImage: UIImage?
    var sampledImage: UIImage?
    var importedColorTokens: [DesignReviewColorToken] = []
    var importedSourceName: String = "Imported"
    var contrastPickTarget: SightedContrastPickTarget?
    var pickedColor: UIColor?
    var pickedPoint: CGPoint?

    var foregroundColor: UIColor = .white
    var backgroundColor: UIColor = UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)

    var isPickerActive = false
    var pickerTarget: PickerTarget?

    enum PickerTarget {
        case foreground
        case background
    }

    var activeColors: [DesignReviewColorToken] {
        switch activeSource {
        case .demo:
            return Self.demoColorTokens
        case .importedImage:
            if !importedColorTokens.isEmpty {
                return importedColorTokens
            }
            if let sampledImage {
                return Self.colorTokens(from: sampledImage, sourceName: importedSourceName)
            }
            if let importedImage {
                return Self.colorTokens(from: importedImage, sourceName: importedSourceName)
            }
            return Self.demoColorTokens
        case .liveSurface:
            if let sampledImage {
                return Self.colorTokens(from: sampledImage, sourceName: "Live")
            }
            return Self.demoColorTokens
        }
    }

    var riskyPairs: [NamedColorPairResult] {
        Self.colorPairs(from: activeColors)
    }

    var riskiestPair: NamedColorPairResult? {
        riskyPairs.first
    }

    var currentContrastRatio: Double {
        ContrastAnalyzer.contrastRatio(between: foregroundColor, and: backgroundColor)
    }

    var currentContrastRating: ContrastRating {
        ContrastAnalyzer.rating(for: currentContrastRatio)
    }

    func useDemoSource() {
        activeSource = .demo
        sampledImage = nil
        contrastPickTarget = nil
        isPickerActive = false
        pickerTarget = nil
    }

    func useImportedImage(_ image: UIImage) {
        importedImage = image
        sampledImage = image
        importedColorTokens = []
        importedSourceName = "Imported"
        activeSource = .importedImage
    }

    func useTeamImportedDesign(_ payload: TeamImportedDesignPayload) {
        importedImage = payload.image
        sampledImage = payload.image
        importedColorTokens = payload.colorTokens
        importedSourceName = payload.sourceName
        activeSource = .importedImage

        if let firstPair = riskiestPair {
            setContrastPair(firstPair)
        }
    }

    func setImportedPickImage(_ image: UIImage, sourceName: String) {
        importedImage = image
        sampledImage = image
        importedSourceName = sourceName

        if importedColorTokens.isEmpty {
            importedColorTokens = Self.colorTokens(from: image, sourceName: sourceName)
        }
    }

    func useImportedColorTokens(_ tokens: [DesignReviewColorToken], sourceName: String = "Imported") {
        importedColorTokens = tokens
        importedSourceName = sourceName
        activeSource = .importedImage

        if let firstPair = riskiestPair {
            setContrastPair(firstPair)
        }
    }

    func clearImportedDesign() {
        importedImage = nil
        sampledImage = nil
        importedColorTokens = []
        importedSourceName = "Imported"
        contrastPickTarget = nil
        isPickerActive = false
        pickerTarget = nil

        if activeSource == .importedImage {
            activeSource = .demo
        }
    }

    func beginPickingContrastColor(_ target: SightedContrastPickTarget) {
        contrastPickTarget = target
    }

    func cancelContrastPicking() {
        contrastPickTarget = nil
    }

    func applyPickedContrastColor(_ color: UIColor, at point: CGPoint? = nil) {
        pickedColor = color
        pickedPoint = point

        switch contrastPickTarget {
        case .text:
            foregroundColor = color
        case .background:
            backgroundColor = color
        case nil:
            break
        }

        contrastPickTarget = nil
    }

    func useLiveSample(_ image: UIImage?) {
        sampledImage = image
        activeSource = .liveSurface
        contrastPickTarget = nil
        isPickerActive = false
        pickerTarget = nil
    }

    func setContrastPair(_ pair: NamedColorPairResult) {
        foregroundColor = pair.color1
        backgroundColor = pair.color2
    }

    func updatePickedColor(_ color: UIColor, target: PickerTarget) {
        switch target {
        case .foreground:
            foregroundColor = color
        case .background:
            backgroundColor = color
        }

        isPickerActive = false
        pickerTarget = nil
    }
}

// MARK: - Shared Analysis Helpers

extension DesignReviewState {
    static let demoColorTokens: [DesignReviewColorToken] = [
        DesignReviewColorToken(
            name: "Surface",
            color: UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0),
            role: "Background"
        ),
        DesignReviewColorToken(
            name: "Card",
            color: UIColor(white: 1.0, alpha: 0.10),
            role: "Container"
        ),
        DesignReviewColorToken(
            name: "Text",
            color: .white,
            role: "Primary text"
        ),
        DesignReviewColorToken(
            name: "Secondary text",
            color: UIColor(white: 1.0, alpha: 0.68),
            role: "Secondary text"
        ),
        DesignReviewColorToken(
            name: "Primary action",
            color: UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1.0),
            role: "Action"
        ),
        DesignReviewColorToken(
            name: "Approved",
            color: UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0),
            role: "Success state"
        ),
        DesignReviewColorToken(
            name: "Warning",
            color: UIColor(red: 1.00, green: 0.58, blue: 0.00, alpha: 1.0),
            role: "Warning state"
        ),
        DesignReviewColorToken(
            name: "Error",
            color: UIColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 1.0),
            role: "Error state"
        )
    ]

    static func colorTokens(from image: UIImage, sourceName: String) -> [DesignReviewColorToken] {
        ColorSampler.dominantColors(from: image, count: 8).enumerated().map { index, color in
            DesignReviewColorToken(
                name: "\(sourceName) color \(index + 1)",
                color: color,
                role: "Sampled color"
            )
        }
    }

    static func colorPairs(from colors: [DesignReviewColorToken]) -> [NamedColorPairResult] {
        var pairs: [NamedColorPairResult] = []

        for firstIndex in 0..<colors.count {
            for secondIndex in (firstIndex + 1)..<colors.count {
                let firstColor = colors[firstIndex]
                let secondColor = colors[secondIndex]
                let ratio = ContrastAnalyzer.contrastRatio(
                    between: firstColor.color,
                    and: secondColor.color
                )

                pairs.append(
                    NamedColorPairResult(
                        firstName: firstColor.name,
                        secondName: secondColor.name,
                        color1: firstColor.color,
                        color2: secondColor.color,
                        ratio: ratio,
                        rating: ContrastAnalyzer.rating(for: ratio)
                    )
                )
            }
        }

        return pairs.sorted { $0.ratio < $1.ratio }
    }
}
