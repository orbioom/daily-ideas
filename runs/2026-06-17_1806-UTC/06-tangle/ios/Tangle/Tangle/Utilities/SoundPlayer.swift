import AVFoundation

/// Lightweight system-sound feedback layer, gated by the sound setting.
/// Uses built-in system sounds so no audio assets are required.
enum SoundPlayer {
    private static let tapID: SystemSoundID = 1104       // soft keyboard tap
    private static let foundID: SystemSoundID = 1325      // gentle "found" chime
    private static let bonusID: SystemSoundID = 1335      // bonus reward tone
    private static let winID: SystemSoundID = 1394        // completion fanfare
    private static let invalidID: SystemSoundID = 1053    // subtle invalid blip

    static func tap(enabled: Bool) { play(tapID, enabled) }
    static func found(enabled: Bool) { play(foundID, enabled) }
    static func bonus(enabled: Bool) { play(bonusID, enabled) }
    static func win(enabled: Bool) { play(winID, enabled) }
    static func invalid(enabled: Bool) { play(invalidID, enabled) }

    private static func play(_ id: SystemSoundID, _ enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(id)
    }
}
