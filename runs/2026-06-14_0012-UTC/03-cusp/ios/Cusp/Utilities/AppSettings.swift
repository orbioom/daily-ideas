import SwiftUI
import Combine

/// Small, persisted user preferences.
///
/// Per conventions these are flags & defaults (not user-owned data — that lives in
/// SwiftData). Values are mirrored into `UserDefaults` so they survive relaunch,
/// and exposed as `@Published` so SwiftUI reliably refreshes when they change
/// (plain `@AppStorage` inside an `ObservableObject` does not publish on its own).
@MainActor
final class AppSettings: ObservableObject {

    private let store: UserDefaults

    @Published var defaultKind: EventKind {
        didSet { store.set(defaultKind.rawValue, forKey: Keys.defaultKind) }
    }
    @Published var weekStartsMonday: Bool {
        didSet { store.set(weekStartsMonday, forKey: Keys.weekStartsMonday) }
    }
    @Published var defaultThemeTag: Int {
        didSet { store.set(defaultThemeTag, forKey: Keys.defaultThemeTag) }
    }
    @Published var showSecondsOnCards: Bool {
        didSet { store.set(showSecondsOnCards, forKey: Keys.showSecondsOnCards) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { store.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    init(store: UserDefaults = .standard) {
        self.store = store
        // Read existing values, falling back to sensible defaults.
        let kindRaw = store.string(forKey: Keys.defaultKind) ?? EventKind.until.rawValue
        self.defaultKind = EventKind(rawValue: kindRaw) ?? .until
        self.weekStartsMonday = store.bool(forKey: Keys.weekStartsMonday) // default false
        self.defaultThemeTag = store.integer(forKey: Keys.defaultThemeTag) // default 0
        // Default true for haptics, so seed it the first time.
        if store.object(forKey: Keys.hapticsEnabled) == nil {
            store.set(true, forKey: Keys.hapticsEnabled)
        }
        self.hapticsEnabled = store.bool(forKey: Keys.hapticsEnabled)
        self.showSecondsOnCards = store.bool(forKey: Keys.showSecondsOnCards) // default false
    }

    var defaultTheme: CardTheme { CardTheme.from(defaultThemeTag) }

    /// A fresh engine configured with the current week-start preference.
    var engine: CountdownEngine { CountdownEngine(weekStartsMonday: weekStartsMonday) }

    private enum Keys {
        static let defaultKind = "defaultKind"
        static let weekStartsMonday = "weekStartsMonday"
        static let defaultThemeTag = "defaultThemeTag"
        static let showSecondsOnCards = "showSecondsOnCards"
        static let hapticsEnabled = "hapticsEnabled"
    }
}
