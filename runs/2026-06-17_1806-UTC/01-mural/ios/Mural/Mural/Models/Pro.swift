import Foundation

/// Central definition of the simulated Pro tier and its free-tier limits.
/// StoreKit-ready: real purchasing would replace `@AppStorage("isPro")` with a transaction observer.
enum Pro {
    /// One-time price label.
    static let priceLabel = "$3.99"

    /// Free tier caps.
    static let freeLibraryLimit = 12
    static let freeCustomPaletteLimit = 2

    /// The unlock bullets shown on the paywall.
    static let unlocks: [(icon: String, title: String, detail: String)] = [
        ("infinity", "Unlimited library", "Save as many wallpapers as you can dream up — no 12-item cap."),
        ("paintpalette.fill", "Unlimited custom palettes", "Build and keep your full personal color system."),
        ("square.grid.2x2.fill", "All premium packs", "Unlock every curated collection, including Pro-only sets."),
        ("4k.tv.fill", "4K ultra export", "Render crisp 4K wallpapers for any device resolution."),
        ("sparkles", "Ultra-clean export", "Grain-free, perfectly smooth gradient output on export.")
    ]
}
