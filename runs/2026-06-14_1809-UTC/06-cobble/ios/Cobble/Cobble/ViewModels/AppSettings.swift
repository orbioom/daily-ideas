import SwiftUI

/// Persisted user preferences that actually change behavior across the app.
@MainActor
final class AppSettings: ObservableObject {
    /// Sparse haptics on placement / clear / game-over.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Sound effects (used by the SoundPlayer; gated everywhere it plays).
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    /// Show the green/red ghost preview when a piece is selected.
    @AppStorage("showGhost") var showGhost: Bool = true
    /// The active block color palette id. Pro palettes fall back to classic if locked.
    @AppStorage("paletteID") var paletteID: String = BlockPalettes.classic.id

    /// Resolve the active palette, honoring Pro gating (a locked Pro palette → classic).
    func palette(isPro: Bool) -> BlockPalette {
        let p = BlockPalettes.palette(id: paletteID)
        if p.isPro && !isPro { return BlockPalettes.classic }
        return p
    }
}
