import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// How planet/sign glyphs are labelled in lists.
enum GlyphStyle: String, CaseIterable, Identifiable {
    case symbol = "Symbols"
    case name = "Names"
    var id: String { rawValue }
}

/// App-wide persisted preferences. All values survive relaunch via `@AppStorage`.
@MainActor
final class AppSettings: ObservableObject {
    /// Required: gates all haptic feedback.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Required: System / Light / Dark.
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue
    /// The primary profile's id (drives the Today + Chart tabs). Empty until a profile exists.
    @AppStorage("primaryProfileID") var primaryProfileID: String = ""
    /// Show glyph symbols vs. spelled-out names in placement lists.
    @AppStorage("glyphStyleRaw") var glyphStyleRaw: String = GlyphStyle.symbol.rawValue
    /// Show exact degrees beside each placement.
    @AppStorage("showDegrees") var showDegrees: Bool = true
    /// Default aspect orb in degrees (3...10). Wider = more aspects shown.
    @AppStorage("defaultOrb") var defaultOrb: Double = 6
    /// Animate the starfield + wheel. Auto-overridden by Reduce Motion at the view layer.
    @AppStorage("animateStars") var animateStars: Bool = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var glyphStyle: GlyphStyle {
        get { GlyphStyle(rawValue: glyphStyleRaw) ?? .symbol }
        set { glyphStyleRaw = newValue.rawValue }
    }
}
