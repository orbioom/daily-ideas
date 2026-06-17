import CoreGraphics
import Foundation

/// The direction a stroke begins, used to place the start marker hint.
enum StrokeStart: String {
    case top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight, center
}

/// A single pen stroke: a polyline of normalized points (each in 0...1) plus
/// the starting region, so the canvas can show the child where to begin.
struct GlyphStroke: Identifiable, Equatable {
    let id = UUID()
    /// Ordered control points in a 0...1 unit square (origin top-left).
    let points: [CGPoint]
    let start: StrokeStart

    static func == (lhs: GlyphStroke, rhs: GlyphStroke) -> Bool {
        lhs.points == rhs.points && lhs.start == rhs.start
    }
}

/// Which curriculum set a glyph belongs to.
enum GlyphSetKind: String, CaseIterable, Identifiable {
    case uppercase = "U"
    case lowercase = "L"
    case numbers = "N"
    case shapes = "S"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .uppercase: return "Uppercase A–Z"
        case .lowercase: return "Lowercase a–z"
        case .numbers: return "Numbers 0–9"
        case .shapes: return "Shapes"
        }
    }

    var shortTitle: String {
        switch self {
        case .uppercase: return "ABC"
        case .lowercase: return "abc"
        case .numbers: return "123"
        case .shapes: return "Shapes"
        }
    }

    var icon: String {
        switch self {
        case .uppercase: return "a.square.fill"
        case .lowercase: return "textformat.size.smaller"
        case .numbers: return "number.square.fill"
        case .shapes: return "square.on.circle.fill"
        }
    }

    /// Uppercase is free; the rest require Pro.
    var requiresPro: Bool { self != .uppercase }
}

/// A complete traceable glyph: a letter, number, or shape.
struct Glyph: Identifiable, Equatable {
    /// Stable key, e.g. "U_A", "L_a", "N_3", "S_circle".
    let key: String
    let set: GlyphSetKind
    /// The big character or symbol shown in the lesson grid.
    let display: String
    /// Spoken / accessibility name, e.g. "Capital A", "Number three", "Circle".
    let label: String
    let strokes: [GlyphStroke]

    var id: String { key }

    static func == (lhs: Glyph, rhs: Glyph) -> Bool { lhs.key == rhs.key }
}
