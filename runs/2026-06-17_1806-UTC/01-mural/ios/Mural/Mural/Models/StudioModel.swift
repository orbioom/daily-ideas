import SwiftUI
import Observation

/// The live working state of the Studio designer. Shared app-wide so other tabs
/// (Palettes, Packs, Library) can load a spec into the designer and switch to it.
@MainActor
@Observable
final class StudioModel {
    var spec: WallpaperSpec
    var aspect: AspectRatioOption
    /// Requested tab index when another screen pushes content into the studio.
    var pendingTabSwitch: Bool = false
    /// The SavedWallpaper id currently being edited, if any (for "Open in Studio").
    var editingID: UUID?

    init(grainDefault: Bool, aspect: AspectRatioOption) {
        let pal = BuiltInPalettes.defaultPalette
        self.aspect = aspect
        self.spec = WallpaperSpec(
            style: .linearGradient,
            paletteHexes: pal.hexes,
            paletteName: pal.name,
            seed: 0xC0FFEE,
            angle: 45,
            grain: grainDefault ? 0.12 : 0,
            vignette: 0.18,
            blur: 0,
            complexity: 6,
            quoteText: nil,
            quoteWeightRaw: 3
        )
    }

    /// Reseed the generative noise with a fresh random seed.
    func shuffle() {
        var rng = SplitMix64(seed: UInt64(Date().timeIntervalSince1970 * 1000) ^ spec.seed)
        spec.seed = rng.next()
        editingID = nil
    }

    /// Replace the active palette.
    func applyPalette(_ palette: Palette) {
        guard !palette.hexes.isEmpty else { return }
        spec.paletteHexes = palette.hexes
        spec.paletteName = palette.name
        editingID = nil
    }

    /// Load a full spec (e.g. from a pack preset or saved wallpaper) into the studio.
    func load(_ newSpec: WallpaperSpec, editingID: UUID? = nil) {
        var loaded = newSpec
        // A fresh working copy gets its own id so it doesn't collide with the source.
        loaded.id = UUID()
        self.spec = loaded
        self.editingID = editingID
        self.pendingTabSwitch = true
    }
}
