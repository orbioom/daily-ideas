import SwiftUI

/// Persisted user preferences that actually change solving behavior.
@MainActor
final class AppSettings: ObservableObject {
    /// Move to the next empty cell automatically after typing a letter.
    @AppStorage("autoAdvance") var autoAdvance: Bool = true
    /// When jumping between slots, skip over slots that are already fully filled.
    @AppStorage("skipFilled") var skipFilled: Bool = true
    /// Require a confirmation before a Reveal (so taps don't spoil the answer).
    @AppStorage("confirmReveal") var confirmReveal: Bool = true
    /// Show the running timer on the board.
    @AppStorage("showTimer") var showTimer: Bool = true
    /// Haptic feedback throughout the app.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// "Pencil" mode enters tentative (greyed) letters until confirmed.
    @AppStorage("pencilMode") var pencilMode: Bool = false
    /// Selected board theme (classic / ink / high-contrast).
    @AppStorage("paletteRaw") var paletteRaw: String = ThemePalette.classic.rawValue

    var palette: ThemePalette {
        get { ThemePalette(rawValue: paletteRaw) ?? .classic }
        set { paletteRaw = newValue.rawValue }
    }

    init() {
        // Keep the global board renderer palette in sync from the start.
        Theme.palette = ThemePalette(rawValue: paletteRaw) ?? .classic
    }

    /// Push the current palette to the global renderer token. Call on change.
    func syncPalette() {
        Theme.palette = palette
    }
}
