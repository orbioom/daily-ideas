import Foundation
import SwiftData

/// Seeds a couple of in-progress and completed artworks so the gallery feels alive
/// on first launch. Runs once, gated by the `didSeed` flag in the app entry.
@MainActor
enum SeedData {
    static func seedIfNeeded(context: ModelContext) {
        // Only seed into an empty store.
        let existing = (try? context.fetch(FetchDescriptor<Artwork>())) ?? []
        guard existing.isEmpty else { return }

        // 1) A fully completed mandala.
        if let mandala = PageLibrary.page(withID: "mandala-bloom") {
            let palette = PaletteLibrary.palette(withID: mandala.suggestedPaletteId) ?? PaletteLibrary.default
            var fills: [Int: String] = [:]
            for region in mandala.regions {
                fills[region.id] = palette.hex(at: region.suggestedColorIndex)
            }
            let art = Artwork(pageID: mandala.id, title: mandala.title, fills: fills,
                              paletteId: palette.id, byNumberMode: false)
            art.createdAt = Date().addingTimeInterval(-86_400 * 3)
            art.updatedAt = Date().addingTimeInterval(-86_400 * 3)
            art.completedAt = Date().addingTimeInterval(-86_400 * 3)
            art.thumbnailData = ThumbnailRenderer.render(page: mandala, fills: fills, palette: palette)
            context.insert(art)
        }

        // 2) An in-progress landscape (~60% filled).
        if let land = PageLibrary.page(withID: "land-sunset") {
            let palette = PaletteLibrary.palette(withID: land.suggestedPaletteId) ?? PaletteLibrary.default
            var fills: [Int: String] = [:]
            let take = Int(Double(land.regions.count) * 0.6)
            for region in land.regions.prefix(max(take, 1)) {
                fills[region.id] = palette.hex(at: region.suggestedColorIndex)
            }
            let art = Artwork(pageID: land.id, title: land.title, fills: fills,
                              paletteId: palette.id, byNumberMode: false)
            art.createdAt = Date().addingTimeInterval(-86_400)
            art.updatedAt = Date().addingTimeInterval(-3_600)
            art.thumbnailData = ThumbnailRenderer.render(page: land, fills: fills, palette: palette)
            context.insert(art)
        }

        // 3) An in-progress geometric (~30% filled).
        if let geo = PageLibrary.page(withID: "geo-prism") {
            let palette = PaletteLibrary.palette(withID: geo.suggestedPaletteId) ?? PaletteLibrary.default
            var fills: [Int: String] = [:]
            let take = Int(Double(geo.regions.count) * 0.3)
            for region in geo.regions.prefix(max(take, 1)) {
                fills[region.id] = palette.hex(at: region.suggestedColorIndex)
            }
            let art = Artwork(pageID: geo.id, title: geo.title, fills: fills,
                              paletteId: palette.id, byNumberMode: false)
            art.createdAt = Date().addingTimeInterval(-7_200)
            art.updatedAt = Date().addingTimeInterval(-1_800)
            art.thumbnailData = ThumbnailRenderer.render(page: geo, fills: fills, palette: palette)
            context.insert(art)
        }

        try? context.save()
    }
}
