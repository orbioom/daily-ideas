import Foundation
import SwiftData

/// A wallpaper the user has saved to their library. The generative recipe is stored
/// as encoded `WallpaperSpec` data and re-rendered on demand.
@Model
final class SavedWallpaper {
    @Attribute(.unique) var id: UUID
    var name: String
    var specData: Data
    var createdAt: Date
    var isFavorite: Bool

    init(id: UUID = UUID(), name: String, specData: Data, createdAt: Date = .now, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.specData = specData
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }

    /// Safely decode the stored spec, falling back to a valid default if data is corrupt.
    var spec: WallpaperSpec {
        if let decoded = try? JSONDecoder().decode(WallpaperSpec.self, from: specData) {
            return decoded
        }
        let pal = BuiltInPalettes.defaultPalette
        return WallpaperSpec(paletteHexes: pal.hexes, paletteName: pal.name)
    }

    /// Persist a new spec into this record.
    func update(with spec: WallpaperSpec) {
        if let data = try? JSONEncoder().encode(spec) {
            specData = data
        }
    }

    static func encode(_ spec: WallpaperSpec) -> Data {
        (try? JSONEncoder().encode(spec)) ?? Data()
    }
}
