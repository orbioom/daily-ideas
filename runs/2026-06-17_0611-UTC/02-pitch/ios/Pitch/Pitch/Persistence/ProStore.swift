import Foundation

/// Static metadata for the simulated one-time Pro purchase. The actual
/// entitlement lives in `@AppStorage("isPro")` per the app conventions; this
/// type only supplies display copy for the paywall.
enum ProInfo {
    static let priceDisplay = "$4.99"

    static let features: [(icon: String, title: String, detail: String)] = [
        ("slider.horizontal.3", "Custom tunings", "Build & save your own string layouts for any instrument."),
        ("metronome", "Advanced metronome", "Triplet & sixteenth subdivisions plus odd meters like 5/4 and 7/8."),
        ("square.stack.3d.up", "Unlimited presets", "Save as many metronome presets as you like."),
        ("tuningfork", "Full-range tone pipe", "Reference tones across the entire chromatic range."),
        ("paintpalette", "Studio themes", "Fine-tune the look to your stage setup.")
    ]

    /// Number of metronome presets allowed on the free tier.
    static let freePresetLimit = 2
}
