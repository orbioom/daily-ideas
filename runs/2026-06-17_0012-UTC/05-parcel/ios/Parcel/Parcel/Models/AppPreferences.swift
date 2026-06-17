import Foundation

/// App-wide preferences backed by UserDefaults, exposed as an @Observable object
/// so views can read/write them without each owning their own @AppStorage.
@Observable
final class AppPreferences {
    /// Number of questions in a Quick Quiz (clamped 5...20).
    var quickLength: Int {
        didSet { UserDefaults.standard.set(quickLength, forKey: Keys.quickLength) }
    }
    /// Number of questions in a full Mock Exam (clamped 20...100).
    var mockLength: Int {
        didSet { UserDefaults.standard.set(mockLength, forKey: Keys.mockLength) }
    }
    /// Pass threshold percent displayed/used for mocks (clamped 60...90).
    var passPercent: Int {
        didSet { UserDefaults.standard.set(passPercent, forKey: Keys.passPercent) }
    }
    /// Whether option order is shuffled per attempt.
    var shuffleOptions: Bool {
        didSet { UserDefaults.standard.set(shuffleOptions, forKey: Keys.shuffle) }
    }
    /// Whether AVSpeechSynthesizer read-aloud is enabled.
    var readAloud: Bool {
        didSet { UserDefaults.standard.set(readAloud, forKey: Keys.readAloud) }
    }
    /// Whether haptic feedback is enabled.
    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }
    /// One-time Pro unlock flag.
    var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: Keys.pro) }
    }

    enum Keys {
        static let quickLength = "quickLength"
        static let mockLength = "mockLength"
        static let passPercent = "passPercent"
        static let shuffle = "shuffleOptions"
        static let readAloud = "readAloud"
        static let haptics = "hapticsEnabled"
        static let pro = "isPro"
    }

    init() {
        let d = UserDefaults.standard
        d.register(defaults: [
            Keys.quickLength: 10,
            Keys.mockLength: 80,
            Keys.passPercent: 75,
            Keys.shuffle: true,
            Keys.readAloud: false,
            Keys.haptics: true,
            Keys.pro: false,
        ])
        self.quickLength = AppPreferences.clamp(d.integer(forKey: Keys.quickLength), 5, 20, fallback: 10)
        self.mockLength = AppPreferences.clamp(d.integer(forKey: Keys.mockLength), 20, 100, fallback: 80)
        self.passPercent = AppPreferences.clamp(d.integer(forKey: Keys.passPercent), 60, 90, fallback: 75)
        self.shuffleOptions = d.bool(forKey: Keys.shuffle)
        self.readAloud = d.bool(forKey: Keys.readAloud)
        self.hapticsEnabled = d.bool(forKey: Keys.haptics)
        self.isPro = d.bool(forKey: Keys.pro)
    }

    private static func clamp(_ value: Int, _ lo: Int, _ hi: Int, fallback: Int) -> Int {
        guard value >= lo, value <= hi else {
            return min(hi, max(lo, value == 0 ? fallback : value))
        }
        return value
    }
}
