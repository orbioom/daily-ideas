import AudioToolbox

/// A subtle, gated mechanical key-click using a built-in system sound.
/// No audio files are bundled; this plays a short system tick.
enum KeySound {
    /// System sound id 1104 is the keyboard "tock" used by the iOS keyboard.
    private static let clickID: SystemSoundID = 1104

    static func click(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(clickID)
    }
}
