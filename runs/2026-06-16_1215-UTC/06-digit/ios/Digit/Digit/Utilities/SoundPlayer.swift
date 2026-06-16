import AVFoundation

/// Plays short built-in system tones for friendly feedback. Gated by the caller.
@MainActor
enum SoundPlayer {
    // System sound IDs (always present on iOS) — no bundled assets required.
    private static let correctID: SystemSoundID = 1057   // gentle "Tink"
    private static let wrongID: SystemSoundID = 1053      // soft low tone
    private static let finishID: SystemSoundID = 1025     // pleasant chime

    static func correct(_ enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(correctID)
    }

    static func wrong(_ enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(wrongID)
    }

    static func finish(_ enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(finishID)
    }
}
