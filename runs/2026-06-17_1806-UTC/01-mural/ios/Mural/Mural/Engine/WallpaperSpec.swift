import SwiftUI

/// A fully self-describing, deterministic recipe for a generated wallpaper.
/// Encoding a spec and re-running the renderer reproduces the identical image.
struct WallpaperSpec: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var style: WallpaperStyle
    /// Palette colors stored as 0xRRGGBB hex strings (stable & Codable).
    var paletteHexes: [String]
    var paletteName: String
    var seed: UInt64
    /// Direction in degrees (0 = left→right).
    var angle: Double
    /// 0...1 grain (film speckle) intensity.
    var grain: Double
    /// 0...1 vignette darkening at the edges.
    var vignette: Double
    /// 0...1 softness/blur amount.
    var blur: Double
    /// Style-dependent density / facet count driver.
    var complexity: Int
    var quoteText: String?
    var quoteWeightRaw: Int

    init(
        id: UUID = UUID(),
        style: WallpaperStyle = .linearGradient,
        paletteHexes: [String],
        paletteName: String,
        seed: UInt64 = 0xC0FFEE,
        angle: Double = 45,
        grain: Double = 0.12,
        vignette: Double = 0.18,
        blur: Double = 0,
        complexity: Int = 6,
        quoteText: String? = nil,
        quoteWeightRaw: Int = 3
    ) {
        self.id = id
        self.style = style
        self.paletteHexes = paletteHexes
        self.paletteName = paletteName
        self.seed = seed
        self.angle = angle
        self.grain = grain
        self.vignette = vignette
        self.blur = blur
        self.complexity = complexity
        self.quoteText = quoteText
        self.quoteWeightRaw = quoteWeightRaw
    }

    /// Resolved SwiftUI colors. Falls back to the brand accent if a palette is empty.
    var colors: [Color] {
        let parsed = paletteHexes.compactMap { Self.hexValue($0) }.map { Color(hex: $0) }
        return parsed.isEmpty ? [Theme.accent, Theme.accentSoft] : parsed
    }

    var quoteWeight: Font.Weight {
        switch quoteWeightRaw {
        case 0: return .light
        case 1: return .regular
        case 2: return .medium
        case 3: return .semibold
        default: return .bold
        }
    }

    /// Parse "0xRRGGBB", "#RRGGBB" or "RRGGBB" into a UInt.
    static func hexValue(_ string: String) -> UInt? {
        var s = string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("0X") { s.removeFirst(2) }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt(s, radix: 16) else { return nil }
        return value
    }

    static func hexString(from value: UInt) -> String {
        String(format: "%06X", value & 0xFFFFFF)
    }
}
