import AudioToolbox

/// Soft, gated system sound cues for phase changes. No bundled audio assets, no network.
enum AudioCue {
    /// A gentle tock used when a new phase begins.
    static func phaseChange(enabled: Bool) {
        guard enabled else { return }
        // 1104 is a soft "Tock" system sound — calm and short.
        AudioServicesPlaySystemSound(1104)
    }

    /// A warmer chime used on session completion.
    static func complete(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1054)
    }
}
