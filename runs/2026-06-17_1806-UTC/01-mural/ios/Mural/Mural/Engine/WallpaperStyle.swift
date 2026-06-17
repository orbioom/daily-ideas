import Foundation

/// The generative styles a wallpaper can be rendered with.
enum WallpaperStyle: String, Codable, CaseIterable, Identifiable, Hashable {
    case linearGradient = "Linear Gradient"
    case meshGradient = "Mesh / Radial"
    case lowPoly = "Low-Poly"
    case stripes = "Stripes"
    case dotField = "Dot Field"
    case aurora = "Aurora"
    case quote = "Quote"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var systemImage: String {
        switch self {
        case .linearGradient: return "square.fill.and.line.vertical.and.square.fill"
        case .meshGradient: return "circle.circle.fill"
        case .lowPoly: return "triangle.fill"
        case .stripes: return "lineweight"
        case .dotField: return "circle.grid.3x3.fill"
        case .aurora: return "waveform.path.ecg"
        case .quote: return "text.quote"
        }
    }

    var blurb: String {
        switch self {
        case .linearGradient: return "Smooth two-or-more stop sweep across the screen."
        case .meshGradient: return "Soft radial glow blooming from a focal point."
        case .lowPoly: return "Faceted triangulated grid with palette-blended facets."
        case .stripes: return "Crisp parallel bands at any angle."
        case .dotField: return "A rhythmic field of dots over a tinted base."
        case .aurora: return "Layered flowing bands like northern lights."
        case .quote: return "Centered words floating over a gradient."
        }
    }

    /// Whether this style exposes an angle/direction control.
    var usesAngle: Bool {
        switch self {
        case .linearGradient, .stripes, .aurora: return true
        case .meshGradient, .lowPoly, .dotField, .quote: return false
        }
    }

    /// Whether this style exposes a complexity control.
    var usesComplexity: Bool {
        switch self {
        case .lowPoly, .stripes, .dotField, .aurora: return true
        case .linearGradient, .meshGradient, .quote: return false
        }
    }

    /// Whether this style uses the quote text + weight controls.
    var usesQuote: Bool { self == .quote }
}
