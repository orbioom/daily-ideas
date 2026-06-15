import SwiftUI

/// Persisted user preferences that actually change behavior across the app.
@MainActor
final class AppSettings: ObservableObject {
    /// Show week-number / age labels in the grid popover and legend.
    @AppStorage("showWeekNumbers") var showWeekNumbers: Bool = true
    /// Sparse haptics on selecting a week, saving, and unlocking.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// How week dots are rendered.
    @AppStorage("dotStyleRaw") var dotStyleRaw: String = DotStyle.round.rawValue
    /// The active color palette id (Pro palettes fall back to Classic if locked).
    @AppStorage("paletteID") var paletteID: String = Palettes.classic.id

    var dotStyle: DotStyle {
        get { DotStyle(rawValue: dotStyleRaw) ?? .round }
        set { dotStyleRaw = newValue.rawValue }
    }

    /// Resolve the active palette, honoring Pro gating.
    func palette(isPro: Bool) -> Palette {
        Palettes.resolved(id: paletteID, isPro: isPro)
    }
}
