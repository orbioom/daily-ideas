import CoreGraphics
import Foundation

/// A single fillable area of a coloring page. Points are normalized (0...1)
/// in the page's square design space.
struct Region: Identifiable, Hashable {
    let id: Int
    let points: [CGPoint]
    /// Index into the page's suggested palette (the "color by number" number is id-relative,
    /// but the suggested color used for the swatch comes from this index).
    let suggestedColorIndex: Int

    var centroid: CGPoint { Geometry.centroid(points) }
}

/// Top-level page categories surfaced in the gallery.
enum PageCategory: String, CaseIterable, Identifiable, Codable {
    case mandala = "Mandala"
    case floral = "Floral"
    case geometric = "Geometric"
    case landscape = "Landscape"
    case whimsical = "Whimsical"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .mandala: return "circle.hexagongrid.fill"
        case .floral: return "leaf.fill"
        case .geometric: return "triangle.fill"
        case .landscape: return "mountain.2.fill"
        case .whimsical: return "sparkles"
        }
    }
}

/// A coloring page definition. Pages live in code (the user's *work* lives in SwiftData).
struct ColoringPage: Identifiable, Hashable {
    let id: String
    let title: String
    let category: PageCategory
    let isPremium: Bool
    /// The palette suggested as the default for this page (matched by id when possible).
    let suggestedPaletteId: String
    let regions: [Region]

    var regionCount: Int { regions.count }

    static func == (lhs: ColoringPage, rhs: ColoringPage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Fast lookup of a region by id (regions are densely numbered from 0, but we don't assume it).
    func region(withID id: Int) -> Region? { regions.first { $0.id == id } }
}
