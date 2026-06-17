import SwiftUI

/// A named, ordered set of colors. Built-in palettes live in code; user palettes are persisted via SwiftData.
struct Palette: Identifiable, Hashable {
    let id: String
    let name: String
    let group: PaletteGroup
    /// 0xRRGGBB hex strings.
    let hexes: [String]

    var colors: [Color] {
        hexes.compactMap { WallpaperSpec.hexValue($0) }.map { Color(hex: $0) }
    }
}

enum PaletteGroup: String, CaseIterable, Identifiable {
    case sunset = "Sunset"
    case pastel = "Pastel"
    case mono = "Mono"
    case neon = "Neon"
    case earth = "Earth"
    case ocean = "Ocean"
    case custom = "My Palettes"

    var id: String { rawValue }
}

/// Built-in curated palettes (≥16).
enum BuiltInPalettes {
    static let all: [Palette] = [
        // Sunset
        Palette(id: "sun-ember", name: "Ember", group: .sunset, hexes: ["FF5E62", "FF9966", "FFC371"]),
        Palette(id: "sun-dusk", name: "Dusk", group: .sunset, hexes: ["2B1055", "7597DE", "FFB199"]),
        Palette(id: "sun-coral", name: "Coral Flush", group: .sunset, hexes: ["F85187", "FF7E5F", "FEB47B"]),

        // Pastel
        Palette(id: "pas-cotton", name: "Cotton", group: .pastel, hexes: ["FBC2EB", "A6C1EE", "C2E9FB"]),
        Palette(id: "pas-sorbet", name: "Sorbet", group: .pastel, hexes: ["FFD3A5", "FD6585", "C3AED6"]),
        Palette(id: "pas-mint", name: "Mint Cream", group: .pastel, hexes: ["D4FC79", "96E6A1", "C2F0E8"]),

        // Mono
        Palette(id: "mono-slate", name: "Slate", group: .mono, hexes: ["111827", "374151", "9CA3AF"]),
        Palette(id: "mono-paper", name: "Paper", group: .mono, hexes: ["F8FAFC", "CBD5E1", "64748B"]),
        Palette(id: "mono-violet", name: "Violet Mono", group: .mono, hexes: ["1E1B2E", "4C3A8C", "7C5CFF"]),

        // Neon
        Palette(id: "neon-vapor", name: "Vaporwave", group: .neon, hexes: ["FF2E97", "8A2BE2", "00E5FF"]),
        Palette(id: "neon-cyber", name: "Cyber", group: .neon, hexes: ["00F5D4", "00BBF9", "9B5DE5"]),
        Palette(id: "neon-pulse", name: "Pulse", group: .neon, hexes: ["F72585", "7209B7", "4361EE"]),

        // Earth
        Palette(id: "earth-clay", name: "Clay", group: .earth, hexes: ["6F4E37", "B08968", "DDB892"]),
        Palette(id: "earth-forest", name: "Forest Floor", group: .earth, hexes: ["1B4332", "40916C", "95D5B2"]),
        Palette(id: "earth-sand", name: "Desert Sand", group: .earth, hexes: ["7F5539", "B08968", "E6CCB2"]),

        // Ocean
        Palette(id: "ocean-deep", name: "Deep Sea", group: .ocean, hexes: ["03045E", "0077B6", "90E0EF"]),
        Palette(id: "ocean-lagoon", name: "Lagoon", group: .ocean, hexes: ["006D77", "83C5BE", "EDF6F9"]),
        Palette(id: "ocean-tide", name: "Tide", group: .ocean, hexes: ["012A4A", "2A6F97", "A9D6E5"])
    ]

    static var defaultPalette: Palette {
        all.first { $0.id == "mono-violet" } ?? all.first ?? Palette(
            id: "fallback", name: "Violet", group: .mono, hexes: ["7C5CFF", "A690FF"]
        )
    }

    static func palette(withID id: String) -> Palette? {
        all.first { $0.id == id }
    }

    static func grouped() -> [(group: PaletteGroup, palettes: [Palette])] {
        PaletteGroup.allCases.compactMap { group in
            guard group != .custom else { return nil }
            let items = all.filter { $0.group == group }
            return items.isEmpty ? nil : (group, items)
        }
    }
}
