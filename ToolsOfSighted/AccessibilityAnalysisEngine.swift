//
//  AccessibilityAnalysisEngine.swift
//  ToolsOfSighted
//
//  Created by Layan Albarrak on 01/06/2026.
//
//  Contrast and color analysis helpers for imported designs.
//

import SwiftUI
import UIKit

// MARK: - Contrast Analyzer

struct ContrastAnalyzer {
    static func luminance(of color: UIColor) -> Double {
        let resolvedColor = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if !resolvedColor.getRed(&r, green: &g, blue: &b, alpha: &a),
           let converted = resolvedColor.cgColor.converted(
                to: CGColorSpaceCreateDeviceRGB(),
                intent: .defaultIntent,
                options: nil
           ),
           let components = converted.components,
           components.count >= 3 {
            r = components[0]
            g = components[1]
            b = components[2]
        }

        func linearize(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearize(r) +
               0.7152 * linearize(g) +
               0.0722 * linearize(b)
    }

    static func contrastRatio(between color1: UIColor, and color2: UIColor) -> Double {
        let l1 = luminance(of: color1)
        let l2 = luminance(of: color2)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func rating(for ratio: Double, largeText: Bool = false) -> ContrastRating {
        let threshold = largeText ? 3.0 : 4.5
        let aaaThreshold = largeText ? 4.5 : 7.0

        if ratio >= aaaThreshold { return .aaa }
        if ratio >= threshold { return .aa }
        if ratio >= 3.0 { return .aaLarge }
        return .fail
    }
}

enum ContrastRating {
    case aaa
    case aa
    case aaLarge
    case fail

    var label: String {
        switch self {
        case .aaa: return "AAA ✅"
        case .aa: return "AA ✅"
        case .aaLarge: return "AA Large Only ⚠️"
        case .fail: return "Fail ❌"
        }
    }

    var color: Color {
        switch self {
        case .aaa, .aa: return .green
        case .aaLarge: return .orange
        case .fail: return .red
        }
    }
}

// MARK: - Color Sampler

struct ColorSampler {
    static func dominantColors(from image: UIImage, count: Int = 6) -> [UIColor] {
        guard let cgImage = image.cgImage else { return [] }
        guard count > 0 else { return [] }

        let size = CGSize(width: 50, height: 50)
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        guard let data = context?.data else { return [] }

        var colorCounts: [String: (color: UIColor, count: Int)] = [:]
        let ptr = data.bindMemory(to: UInt8.self, capacity: Int(size.width * size.height) * 4)

        for y in 0..<Int(size.height) {
            for x in 0..<Int(size.width) {
                let offset = (y * Int(size.width) + x) * 4
                let r = Int(ptr[offset])
                let g = Int(ptr[offset + 1])
                let b = Int(ptr[offset + 2])
                let a = Int(ptr[offset + 3])

                guard a > 128 else { continue }

                let rBucket = (r / 32) * 32
                let gBucket = (g / 32) * 32
                let bBucket = (b / 32) * 32
                let key = "\(rBucket)-\(gBucket)-\(bBucket)"

                if let existing = colorCounts[key] {
                    colorCounts[key] = (existing.color, existing.count + 1)
                } else {
                    let color = UIColor(
                        red: CGFloat(rBucket) / 255,
                        green: CGFloat(gBucket) / 255,
                        blue: CGFloat(bBucket) / 255,
                        alpha: 1.0
                    )
                    colorCounts[key] = (color, 1)
                }
            }
        }

        return colorCounts.values
            .sorted { $0.count > $1.count }
            .prefix(max(count, 0))
            .map { $0.color }
    }

    static func dominantColorTokens(
        from image: UIImage,
        sourceName: String = "Imported",
        count: Int = 8
    ) -> [DesignReviewColorToken] {
        dominantColors(from: image, count: count).enumerated().map { index, color in
            DesignReviewColorToken(
                name: "\(sourceName) color \(index + 1)",
                color: color,
                role: "Sampled color"
            )
        }
    }

    static func colorPairs(from colors: [UIColor]) -> [ColorPairResult] {
        var pairs: [ColorPairResult] = []

        for firstIndex in 0..<colors.count {
            for secondIndex in (firstIndex + 1)..<colors.count {
                let firstColor = colors[firstIndex]
                let secondColor = colors[secondIndex]
                let ratio = ContrastAnalyzer.contrastRatio(
                    between: firstColor,
                    and: secondColor
                )

                pairs.append(
                    ColorPairResult(
                        color1: firstColor,
                        color2: secondColor,
                        ratio: ratio,
                        rating: ContrastAnalyzer.rating(for: ratio)
                    )
                )
            }
        }

        return pairs.sorted { $0.ratio < $1.ratio }
    }
}

// MARK: - Accessibility Analysis Engine

struct AccessibilityAnalysisEngine {
    static func analyzeImportedDesign(
        image: UIImage,
        sourceName: String = "Imported Design",
        maxColors: Int = 8
    ) -> TeamImportedDesignPayload {
        let tokens = ColorSampler.dominantColorTokens(
            from: image,
            sourceName: sourceName,
            count: maxColors
        )

        return TeamImportedDesignPayload(
            image: image,
            colorTokens: tokens,
            sourceName: sourceName
        )
    }

    static func analyzeColorPairs(from colors: [UIColor]) -> [ColorPairResult] {
        ColorSampler.colorPairs(from: colors)
    }

    static func analyzeColorPairs(from tokens: [DesignReviewColorToken]) -> [NamedColorPairResult] {
        DesignReviewState.colorPairs(from: tokens)
    }
}

// MARK: - Color Pair Result

struct ColorPairResult: Identifiable {
    let id = UUID()
    let color1: UIColor
    let color2: UIColor
    let ratio: Double
    let rating: ContrastRating

    var hex1: String { color1.hexString }
    var hex2: String { color2.hexString }
}

extension UIColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(
                format: "#%02X%02X%02X",
                Int(r * 255),
                Int(g * 255),
                Int(b * 255)
            )
        }

        guard let converted = cgColor.converted(
            to: CGColorSpaceCreateDeviceRGB(),
            intent: .defaultIntent,
            options: nil
        ),
        let components = converted.components,
        components.count >= 3 else {
            return "#000000"
        }

        return String(
            format: "#%02X%02X%02X",
            Int(components[0] * 255),
            Int(components[1] * 255),
            Int(components[2] * 255)
        )
    }
}
