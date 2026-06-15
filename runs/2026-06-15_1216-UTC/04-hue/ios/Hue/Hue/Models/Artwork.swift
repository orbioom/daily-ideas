import Foundation
import SwiftData

/// A user's saved coloring work for a particular page. Page geometry lives in code;
/// here we only persist which color fills each region plus light metadata.
@Model
final class Artwork {
    /// Identifies the `ColoringPage` this work belongs to.
    var pageID: String = ""
    var title: String = ""
    /// JSON-encoded [regionID(String): hex] map. Stored as Data for compactness/safety.
    var fillsData: Data = Data()
    var paletteId: String = PaletteLibrary.default.id
    var byNumberMode: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date?
    /// PNG thumbnail rendered from the current fills (optional; regenerated on save).
    var thumbnailData: Data?

    init(pageID: String,
         title: String,
         fills: [Int: String] = [:],
         paletteId: String = PaletteLibrary.default.id,
         byNumberMode: Bool = false) {
        self.pageID = pageID
        self.title = title
        self.paletteId = paletteId
        self.byNumberMode = byNumberMode
        self.createdAt = Date()
        self.updatedAt = Date()
        self.fillsData = Artwork.encode(fills)
    }

    // MARK: - Fills encode/decode (crash-safe)

    /// Decode the fills map. Returns empty on any decode failure.
    var fills: [Int: String] {
        get { Artwork.decode(fillsData) }
        set {
            fillsData = Artwork.encode(newValue)
            updatedAt = Date()
        }
    }

    var filledCount: Int { fills.count }

    var isCompleted: Bool { completedAt != nil }

    static func encode(_ map: [Int: String]) -> Data {
        // Keys must be String for JSON dictionaries.
        let stringKeyed = Dictionary(uniqueKeysWithValues: map.map { (String($0.key), $0.value) })
        return (try? JSONEncoder().encode(stringKeyed)) ?? Data()
    }

    static func decode(_ data: Data) -> [Int: String] {
        guard !data.isEmpty,
              let stringKeyed = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        var out: [Int: String] = [:]
        for (k, v) in stringKeyed {
            if let i = Int(k) { out[i] = v }
        }
        return out
    }
}

/// A user-created palette (a Pro feature). Colors stored as hex strings encoded to Data.
@Model
final class CustomPalette {
    var name: String = ""
    var colorsData: Data = Data()
    var createdAt: Date = Date()
    /// Stable identifier that survives relaunch (used to match a chosen default palette).
    var uuid: String = UUID().uuidString

    init(name: String, colorHexes: [String]) {
        self.name = name
        self.createdAt = Date()
        self.uuid = UUID().uuidString
        self.colorsData = CustomPalette.encode(colorHexes)
    }

    var colorHexes: [String] {
        get { CustomPalette.decode(colorsData) }
        set { colorsData = CustomPalette.encode(newValue) }
    }

    /// A stable id that survives relaunch; used to match a default palette.
    var paletteId: String { "custom-\(uuid)" }

    func asPalette() -> Palette {
        Palette(id: paletteId, name: name.isEmpty ? "Custom" : name, colorHexes: colorHexes)
    }

    static func encode(_ hexes: [String]) -> Data {
        (try? JSONEncoder().encode(hexes)) ?? Data()
    }

    static func decode(_ data: Data) -> [String] {
        guard !data.isEmpty, let arr = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return arr
    }
}
