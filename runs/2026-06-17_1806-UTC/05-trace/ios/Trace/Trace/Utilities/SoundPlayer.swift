import AVFoundation

/// Plays short built-in system sounds for feedback. Gated by the caller via the
/// `enabled` flag (wired to `settings.soundEnabled`). Uses AudioToolbox system
/// sounds so no audio assets are needed.
enum SoundPlayer {
    // System sound IDs (documented "Tink", "begin record" style short tones).
    private static let successID: SystemSoundID = 1025   // short cheerful chime
    private static let tapID: SystemSoundID = 1104        // light key-press tick
    private static let tryAgainID: SystemSoundID = 1053   // soft low tone

    static func success(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(successID)
    }

    static func tap(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(tapID)
    }

    static func tryAgain(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(tryAgainID)
    }
}
