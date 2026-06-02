//
//  FingertipToolsCore.swift
//  ToolsOfSighted
//
//  Created by Layan Albarrak on 01/06/2026.
//
//  Core state helpers and shared utilities for Fingertip Tools.
//

import SwiftUI
import UIKit
import Observation

// MARK: - FingertipToolsViewModel

/// Lightweight local model for standalone Fingertip Tools previews or experiments.
/// The live immersive experience uses `ToolState` and `DesignReviewState`.
@Observable
class FingertipToolsViewModel {
    var isLensActive: Bool = false
    var selectedCVDType: ToolState.CVDType = .protanopia
    var cvdIntensity: Double = 1.0
    var filterApplicationMode: ToolState.FilterApplicationMode = .fullWorld
}

// MARK: - UIColor Extension

extension UIColor {
    /// Linear interpolation between two colors
    func interpolate(to target: UIColor, amount: Double) -> UIColor {
        let clampedAmount = max(0, min(1, amount))

        var sourceRed: CGFloat = 0
        var sourceGreen: CGFloat = 0
        var sourceBlue: CGFloat = 0
        var sourceAlpha: CGFloat = 0

        var targetRed: CGFloat = 0
        var targetGreen: CGFloat = 0
        var targetBlue: CGFloat = 0
        var targetAlpha: CGFloat = 0

        guard getRed(&sourceRed, green: &sourceGreen, blue: &sourceBlue, alpha: &sourceAlpha),
              target.getRed(&targetRed, green: &targetGreen, blue: &targetBlue, alpha: &targetAlpha) else {
            return self
        }

        return UIColor(
            red: sourceRed + (targetRed - sourceRed) * CGFloat(clampedAmount),
            green: sourceGreen + (targetGreen - sourceGreen) * CGFloat(clampedAmount),
            blue: sourceBlue + (targetBlue - sourceBlue) * CGFloat(clampedAmount),
            alpha: sourceAlpha + (targetAlpha - sourceAlpha) * CGFloat(clampedAmount)
        )
    }
}
