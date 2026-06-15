import SwiftUI

/// A curated set of colors used to fill regions. Built-in palettes live in code;
/// user palettes are persisted via the `CustomPalette` SwiftData model.
struct Palette: Identifiable, Hashable {
    let id: String
    let name: String
    /// Stored as hex strings so palettes can round-trip to/from persistence trivially.
    let colorHexes: [String]

    var colors: [Color] { colorHexes.map { Color(hexString: $0) ?? Theme.regionUnfilled } }

    /// Safe color access for a region's suggested index (wraps / clamps).
    func color(at index: Int) -> Color {
        guard !colorHexes.isEmpty else { return Theme.regionUnfilled }
        let i = ((index % colorHexes.count) + colorHexes.count) % colorHexes.count
        return Color(hexString: colorHexes[i]) ?? Theme.regionUnfilled
    }

    func hex(at index: Int) -> String {
        guard !colorHexes.isEmpty else { return "FFFFFF" }
        let i = ((index % colorHexes.count) + colorHexes.count) % colorHexes.count
        return colorHexes[i]
    }
}

enum PaletteLibrary {
    /// ≥6 curated palettes, each 12–16 colors. Hex strings are uppercase RGB.
    static let all: [Palette] = [
        Palette(id: "blossom", name: "Blossom", colorHexes: [
            "F7D6E0", "F4A6C0", "EE7FA7", "D85A8E", "C04CC8", "9B4DCA",
            "7E5BD8", "5F7BE0", "82C0CC", "BEE3DB", "F7E1A0", "F2B868",
            "E58E5A", "C95B4E"
        ]),
        Palette(id: "meadow", name: "Meadow", colorHexes: [
            "EAF4D3", "C7E5A0", "9ED06F", "6FB552", "4C9A3C", "2F7D32",
            "BFE6C8", "8FD3B6", "5FC0A0", "3DA88C", "D9F0E6", "A0D8DE",
            "6FBFD0"
        ]),
        Palette(id: "dusk", name: "Dusk", colorHexes: [
            "FCE7C8", "F7C088", "F09565", "E26B5C", "C04C6A", "9B3F73",
            "6E3B82", "4A3A78", "33335E", "5C6BA8", "8FA0D0", "C0CCE8",
            "E8D6F0", "F0C0DC"
        ]),
        Palette(id: "ocean", name: "Ocean", colorHexes: [
            "E3F6F5", "BAE8E8", "8FD6DC", "5FC0CC", "3CA0BD", "2E7DA8",
            "276490", "1F4E78", "2A3D66", "4C5B92", "7A86B8", "AAB6DC",
            "D6DEF2"
        ]),
        Palette(id: "ember", name: "Ember", colorHexes: [
            "FFF0D6", "FBD99A", "F6B85F", "F0913C", "E66A33", "D8482E",
            "C0302E", "9B2436", "73213E", "B0485E", "D86E7C", "EE9CA6",
            "F8C8CE", "FBE0E2"
        ]),
        Palette(id: "pastel", name: "Soft Pastels", colorHexes: [
            "FBE4E7", "FBE7CF", "FBF6CF", "E7F6D5", "D5F6E7", "D5EFFB",
            "E0DEFB", "F0DEFB", "FBDEEF", "F2F2F2", "E2DCD6", "C9C0CC",
            "FFFFFF", "DCD2E0"
        ]),
        Palette(id: "earth", name: "Earth", colorHexes: [
            "F2E9DC", "E4D2B8", "D2B48C", "BD9466", "A57850", "8A5E3C",
            "6E472C", "53341F", "9C8C6E", "BFB394", "DAD2B8", "C7AE8A",
            "8F7A5C"
        ]),
        Palette(id: "jewel", name: "Jewel Tones", colorHexes: [
            "F4D6E8", "D85AA8", "B23C8E", "8E2C8C", "6A2A8E", "4A2C8E",
            "2C3E8E", "1F6FA0", "1F9C8C", "3CB06A", "C9A227", "D8742A",
            "C0392B", "8E1F3C"
        ])
    ]

    static let `default`: Palette = all.first ?? Palette(id: "blossom", name: "Blossom", colorHexes: ["C04CC8"])

    static func palette(withID id: String) -> Palette? { all.first { $0.id == id } }

    /// Resolve any palette id (built-in or user) given a list of user palettes.
    static func resolve(id: String, custom: [Palette]) -> Palette {
        if let p = palette(withID: id) { return p }
        if let p = custom.first(where: { $0.id == id }) { return p }
        return `default`
    }
}
