import SwiftUI

/// Centralized, persisted user preferences. Backed by `@AppStorage`.
@MainActor
final class AppSettings: ObservableObject {
    // Appearance
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue

    // Reader defaults
    @AppStorage("defaultReaderTheme") var defaultReaderThemeRaw = ReaderTheme.sepia.rawValue
    @AppStorage("defaultReaderFont") var defaultReaderFontRaw = ReaderFont.serif.rawValue
    @AppStorage("readerFontSize") var readerFontSize: Double = 19
    @AppStorage("readerLineSpacing") var readerLineSpacing: Double = 8

    // Reading
    @AppStorage("wordsPerMinute") var wordsPerMinute: Int = 200

    // Behavior
    @AppStorage("hapticsEnabled") var hapticsEnabled = true

    var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    var defaultReaderTheme: ReaderTheme {
        ReaderTheme(rawValue: defaultReaderThemeRaw) ?? .sepia
    }

    var defaultReaderFont: ReaderFont {
        ReaderFont(rawValue: defaultReaderFontRaw) ?? .serif
    }

    /// Fire a haptic only when the user has them enabled.
    func haptic(_ action: () -> Void) {
        if hapticsEnabled { action() }
    }
}
