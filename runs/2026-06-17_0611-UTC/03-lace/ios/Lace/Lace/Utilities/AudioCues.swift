import Foundation
import AVFoundation
import AudioToolbox

/// Spoken coaching cues and short countdown beeps. Speech uses
/// `AVSpeechSynthesizer`; beeps use a system sound so no audio asset is needed.
/// All output is gated by the caller (Settings toggles), and the synthesizer is
/// owned by the engine so utterances can be cancelled on stop.
final class AudioCues {

    private let synthesizer = AVSpeechSynthesizer()

    init() {
        configureSession()
    }

    /// Mix with other audio (e.g. the user's music) and duck it briefly while speaking.
    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // try? — a failed session activation must never crash a workout.
        try? session.setCategory(.playback,
                                  mode: .spokenAudio,
                                  options: [.duckOthers, .mixWithOthers])
        try? session.setActive(true, options: [])
    }

    /// Speak a coaching phrase. No-op when `enabled` is false or the phrase is empty.
    func speak(_ phrase: String, enabled: Bool) {
        guard enabled, !phrase.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    /// A short countdown beep used in the final seconds of an interval.
    func beep(enabled: Bool) {
        guard enabled else { return }
        // 1057 is a short, neutral system tick. AudioServices is robust and
        // requires no bundled asset.
        AudioServicesPlaySystemSound(SystemSoundID(1057))
    }

    /// A distinct end-of-interval tone.
    func transitionTone(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(SystemSoundID(1113))
    }

    /// Stop any in-flight speech immediately (used on pause / stop).
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Release the audio session (used when the player closes).
    func deactivate() {
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
