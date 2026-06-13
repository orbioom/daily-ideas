import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

/// A full set of photo adjustments. Every value is neutral at its default,
/// so `Adjustments()` is the identity edit.
struct Adjustments: Codable, Equatable {
    var exposure = 0.0      // -1…1  → EV ±1.5
    var brightness = 0.0    // -1…1  → ±0.22
    var contrast = 0.0      // -1…1  → contrast 0.65…1.35
    var saturation = 0.0    // -1…1  → 0…2
    var vibrance = 0.0      // -1…1
    var warmth = 0.0        // -1…1
    var tint = 0.0          // -1…1
    var shadows = 0.0       // -1…1  (lift / crush)
    var highlights = 0.0    // -1…1  (recover / boost)
    var fade = 0.0          //  0…1  (lifted blacks, matte film look)
    var sharpness = 0.0     //  0…1
    var vignette = 0.0      //  0…1
    var grain = 0.0         //  0…1

    static let neutral = Adjustments()
    var isNeutral: Bool { self == .neutral }

    /// Field identifiers for the slider UI.
    enum Field: String, CaseIterable, Identifiable {
        case exposure, brightness, contrast, saturation, vibrance, warmth, tint,
             shadows, highlights, fade, sharpness, vignette, grain
        var id: String { rawValue }
        var label: String {
            switch self {
            case .exposure: return "Exposure"
            case .brightness: return "Brightness"
            case .contrast: return "Contrast"
            case .saturation: return "Saturation"
            case .vibrance: return "Vibrance"
            case .warmth: return "Warmth"
            case .tint: return "Tint"
            case .shadows: return "Shadows"
            case .highlights: return "Highlights"
            case .fade: return "Fade"
            case .sharpness: return "Sharpen"
            case .vignette: return "Vignette"
            case .grain: return "Grain"
            }
        }
        var icon: String {
            switch self {
            case .exposure: return "sun.max.fill"
            case .brightness: return "light.max"
            case .contrast: return "circle.lefthalf.filled"
            case .saturation: return "drop.fill"
            case .vibrance: return "drop.halffull"
            case .warmth: return "thermometer.sun.fill"
            case .tint: return "paintpalette.fill"
            case .shadows: return "moon.fill"
            case .highlights: return "rays"
            case .fade: return "square.fill.on.square.fill"
            case .sharpness: return "triangle.fill"
            case .vignette: return "circle.dashed"
            case .grain: return "circle.grid.3x3.fill"
            }
        }
        /// True for sliders centered at zero (bidirectional).
        var bipolar: Bool {
            switch self {
            case .fade, .sharpness, .vignette, .grain: return false
            default: return true
            }
        }
    }

    subscript(_ field: Field) -> Double {
        get {
            switch field {
            case .exposure: return exposure
            case .brightness: return brightness
            case .contrast: return contrast
            case .saturation: return saturation
            case .vibrance: return vibrance
            case .warmth: return warmth
            case .tint: return tint
            case .shadows: return shadows
            case .highlights: return highlights
            case .fade: return fade
            case .sharpness: return sharpness
            case .vignette: return vignette
            case .grain: return grain
            }
        }
        set {
            switch field {
            case .exposure: exposure = newValue
            case .brightness: brightness = newValue
            case .contrast: contrast = newValue
            case .saturation: saturation = newValue
            case .vibrance: vibrance = newValue
            case .warmth: warmth = newValue
            case .tint: tint = newValue
            case .shadows: shadows = newValue
            case .highlights: highlights = newValue
            case .fade: fade = newValue
            case .sharpness: sharpness = newValue
            case .vignette: vignette = newValue
            case .grain: grain = newValue
            }
        }
    }

    /// Builds the processed CIImage by chaining Core Image filters.
    func apply(to input: CIImage) -> CIImage {
        var image = input

        // Exposure
        if exposure != 0 {
            let f = CIFilter.exposureAdjust()
            f.inputImage = image; f.ev = Float(exposure * 1.5)
            image = f.outputImage ?? image
        }

        // Brightness / contrast / saturation
        if brightness != 0 || contrast != 0 || saturation != 0 {
            let f = CIFilter.colorControls()
            f.inputImage = image
            f.brightness = Float(brightness * 0.22)
            f.contrast = Float(1.0 + contrast * 0.35)
            f.saturation = Float(1.0 + saturation)
            image = f.outputImage ?? image
        }

        // Vibrance
        if vibrance != 0 {
            let f = CIFilter.vibrance()
            f.inputImage = image; f.amount = Float(vibrance)
            image = f.outputImage ?? image
        }

        // Warmth & tint
        if warmth != 0 || tint != 0 {
            let f = CIFilter.temperatureAndTint()
            f.inputImage = image
            f.neutral = CIVector(x: 6500, y: 0)
            f.targetNeutral = CIVector(x: 6500 + warmth * 2200, y: tint * 50)
            image = f.outputImage ?? image
        }

        // Tonal curve: shadows, highlights, fade (matte lifted blacks)
        if shadows != 0 || highlights != 0 || fade != 0 {
            let f = CIFilter.toneCurve()
            f.inputImage = image
            let lift = fade * 0.18
            let p0y = clamp(lift, 0, 0.4)
            let p1y = clamp(0.25 + shadows * 0.12 + lift * 0.6, p0y + 0.02, 0.6)
            let p3y = clamp(0.75 + highlights * 0.12, 0.62, 0.98)
            let p4y = clamp(1.0 - max(0, -highlights) * 0.05, p3y + 0.02, 1.0)
            f.point0 = CGPoint(x: 0, y: p0y)
            f.point1 = CGPoint(x: 0.25, y: p1y)
            f.point2 = CGPoint(x: 0.5, y: 0.5)
            f.point3 = CGPoint(x: 0.75, y: p3y)
            f.point4 = CGPoint(x: 1, y: p4y)
            image = f.outputImage ?? image
        }

        // Sharpen
        if sharpness > 0 {
            let f = CIFilter.sharpenLuminance()
            f.inputImage = image; f.sharpness = Float(sharpness * 1.2)
            image = f.outputImage ?? image
        }

        // Grain (soft-light gray noise centered at 0.5)
        if grain > 0 {
            let noise = CIFilter.randomGenerator().outputImage?.cropped(to: image.extent)
            if let noise {
                let desat = CIFilter.colorControls()
                desat.inputImage = noise; desat.saturation = 0
                let a = grain * 0.5
                let cm = CIFilter.colorMatrix()
                cm.inputImage = desat.outputImage
                cm.rVector = CIVector(x: a, y: 0, z: 0, w: 0)
                cm.gVector = CIVector(x: 0, y: a, z: 0, w: 0)
                cm.bVector = CIVector(x: 0, y: 0, z: a, w: 0)
                cm.aVector = CIVector(x: 0, y: 0, z: 0, w: 0)
                cm.biasVector = CIVector(x: 0.5 * (1 - a), y: 0.5 * (1 - a), z: 0.5 * (1 - a), w: 1)
                let blend = CIFilter.softLightBlendMode()
                blend.inputImage = cm.outputImage
                blend.backgroundImage = image
                image = blend.outputImage ?? image
            }
        }

        // Vignette
        if vignette > 0 {
            let f = CIFilter.vignette()
            f.inputImage = image
            f.intensity = Float(vignette * 1.4)
            f.radius = Float(1.6)
            image = f.outputImage ?? image
        }

        return image.cropped(to: input.extent)
    }
}

private func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double { min(max(v, lo), hi) }
