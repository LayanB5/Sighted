//
//  ColorBlindnessSimulator.swift
//  ToolsOfSighted
//
//  Created by Layan Albarrak on 01/06/2026.
//
//  Color blindness simulation helpers for images and colors.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum ColorBlindnessType: String, CaseIterable, Identifiable {
    case protanopia = "Protanopia"
    case deuteranopia = "Deuteranopia"
    case tritanopia = "Tritanopia"

    var id: String { rawValue }

    var shortCode: String {
        switch self {
        case .protanopia:
            return "P"
        case .deuteranopia:
            return "D"
        case .tritanopia:
            return "T"
        }
    }

    var description: String {
        switch self {
        case .protanopia:
            return "Red-blind simulation"
        case .deuteranopia:
            return "Green-blind simulation"
        case .tritanopia:
            return "Blue-yellow simulation"
        }
    }
}

struct ColorBlindnessSimulator {
    static func simulate(_ image: UIImage, type: ColorBlindnessType = .deuteranopia) -> UIImage {
        guard let inputCIImage = CIImage(image: image) else { return image }

        let filter = CIFilter.colorMatrix()
        filter.inputImage = inputCIImage

        let matrix = matrixVectors(for: type)
        filter.rVector = matrix.r
        filter.gVector = matrix.g
        filter.bVector = matrix.b
        filter.aVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0)

        guard let outputImage = filter.outputImage else { return image }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: inputCIImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    static func simulate(_ color: UIColor, type: ColorBlindnessType = .deuteranopia) -> UIColor {
        let resolvedColor = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if !resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha),
           let converted = resolvedColor.cgColor.converted(
                to: CGColorSpaceCreateDeviceRGB(),
                intent: .defaultIntent,
                options: nil
           ),
           let components = converted.components,
           components.count >= 3 {
            red = components[0]
            green = components[1]
            blue = components[2]
            alpha = resolvedColor.cgColor.alpha
        }

        let matrix = scalarMatrix(for: type)

        let simulatedRed = clamp(red * matrix.r.0 + green * matrix.r.1 + blue * matrix.r.2)
        let simulatedGreen = clamp(red * matrix.g.0 + green * matrix.g.1 + blue * matrix.g.2)
        let simulatedBlue = clamp(red * matrix.b.0 + green * matrix.b.1 + blue * matrix.b.2)

        return UIColor(
            red: simulatedRed,
            green: simulatedGreen,
            blue: simulatedBlue,
            alpha: alpha
        )
    }

    static func type(from cvdType: ToolState.CVDType) -> ColorBlindnessType {
        switch cvdType {
        case .protanopia:
            return .protanopia
        case .deuteranopia:
            return .deuteranopia
        case .tritanopia:
            return .tritanopia
        }
    }

    static func simulate(_ image: UIImage, cvdType: ToolState.CVDType) -> UIImage {
        simulate(image, type: type(from: cvdType))
    }

    static func simulate(_ color: UIColor, cvdType: ToolState.CVDType) -> UIColor {
        simulate(color, type: type(from: cvdType))
    }

    private static func matrixVectors(for type: ColorBlindnessType) -> (r: CIVector, g: CIVector, b: CIVector) {
        let matrix = scalarMatrix(for: type)

        return (
            r: CIVector(x: matrix.r.0, y: matrix.r.1, z: matrix.r.2, w: 0.0),
            g: CIVector(x: matrix.g.0, y: matrix.g.1, z: matrix.g.2, w: 0.0),
            b: CIVector(x: matrix.b.0, y: matrix.b.1, z: matrix.b.2, w: 0.0)
        )
    }

    private static func scalarMatrix(for type: ColorBlindnessType) -> (r: (CGFloat, CGFloat, CGFloat), g: (CGFloat, CGFloat, CGFloat), b: (CGFloat, CGFloat, CGFloat)) {
        switch type {
        case .protanopia:
            return (
                r: (0.152286, 1.052583, -0.204868),
                g: (0.114503, 0.786281, 0.099216),
                b: (-0.003882, -0.048116, 1.051998)
            )

        case .deuteranopia:
            return (
                r: (0.367322, 0.860646, -0.227968),
                g: (0.280085, 0.672501, 0.047413),
                b: (-0.011820, 0.042940, 0.968881)
            )

        case .tritanopia:
            return (
                r: (1.255528, -0.076749, -0.178779),
                g: (-0.078411, 0.930809, 0.147602),
                b: (0.004733, 0.691367, 0.303900)
            )
        }
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }
}
