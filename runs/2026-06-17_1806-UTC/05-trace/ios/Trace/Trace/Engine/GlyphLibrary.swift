import CoreGraphics
import Foundation

/// Central catalog of every traceable glyph. Stroke data lives in the
/// `GlyphLibrary+*.swift` extension files for readability.
enum GlyphLibrary {

    /// All glyphs for a given set, in curriculum order.
    static func glyphs(for set: GlyphSetKind) -> [Glyph] {
        switch set {
        case .uppercase: return uppercase
        case .lowercase: return lowercase
        case .numbers: return numbers
        case .shapes: return shapes
        }
    }

    /// Every glyph across every set.
    static var all: [Glyph] {
        GlyphSetKind.allCases.flatMap { glyphs(for: $0) }
    }

    /// Lookup by key (e.g. "U_A"). Returns nil if unknown — callers guard.
    static func glyph(forKey key: String) -> Glyph? {
        all.first { $0.key == key }
    }

    /// Build the glyph for a single character if it exists in any set.
    /// Used by custom word tracing — prefers uppercase forms.
    static func glyph(forCharacter ch: Character) -> Glyph? {
        if ch.isUppercase || ch.isLetter {
            let upperKey = "U_\(String(ch).uppercased())"
            if let g = glyph(forKey: upperKey) { return g }
        }
        if ch.isLowercase {
            let lowerKey = "L_\(String(ch).lowercased())"
            if let g = glyph(forKey: lowerKey) { return g }
        }
        if ch.isNumber {
            return glyph(forKey: "N_\(String(ch))")
        }
        return nil
    }
}

/// Small helper to build normalized points concisely in the data files.
@inline(__always)
func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
