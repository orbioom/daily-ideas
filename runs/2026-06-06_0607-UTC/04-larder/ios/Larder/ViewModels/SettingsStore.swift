import SwiftUI
import Observation

/// Small key/value preferences (permitted in UserDefaults — never the primary store).
/// Every preference here actually changes behavior and is applied immediately or on
/// next relevant action.
@Observable
final class SettingsStore {

    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light:  return .light
            case .dark:   return .dark
            }
        }
    }

    private let defaults: UserDefaults

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    /// How many days ahead counts as "expiring soon". Drives bucketing and the dashboard.
    var expirySoonWindowDays: Int {
        didSet { defaults.set(expirySoonWindowDays, forKey: Keys.window) }
    }
    /// The location pre-selected when composing a new item. Stored by UUID string.
    var defaultLocationID: String {
        didSet { defaults.set(defaultLocationID, forKey: Keys.defaultLocation) }
    }
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }
    /// Master switch for scheduling expiry reminders. The actual OS permission is
    /// requested lazily and denial is handled gracefully (see NotificationManager).
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }
    var hasOnboarded: Bool {
        didSet { defaults.set(hasOnboarded, forKey: Keys.onboarded) }
    }
    var hasSeeded: Bool {
        didSet { defaults.set(hasSeeded, forKey: Keys.seeded) }
    }

    private enum Keys {
        static let appearance = "settings.appearance"
        static let window = "settings.expirySoonWindowDays"
        static let defaultLocation = "settings.defaultLocationID"
        static let haptics = "settings.haptics"
        static let notifications = "settings.notifications"
        static let onboarded = "settings.hasOnboarded"
        static let seeded = "settings.hasSeeded"
    }

    /// Allowed window choices offered in Settings.
    static let windowChoices = [3, 5, 7, 14, 30]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        let storedWindow = defaults.object(forKey: Keys.window) as? Int
        self.expirySoonWindowDays = storedWindow ?? 7
        self.defaultLocationID = defaults.string(forKey: Keys.defaultLocation) ?? ""
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: Keys.notifications) as? Bool ?? false
        self.hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        self.hasSeeded = defaults.bool(forKey: Keys.seeded)
    }

    /// Clears flags/prefs back to first-run defaults (used by the reset path).
    func resetToDefaults() {
        appearance = .system
        expirySoonWindowDays = 7
        defaultLocationID = ""
        hapticsEnabled = true
        notificationsEnabled = false
        hasOnboarded = false
        hasSeeded = false
    }
}
