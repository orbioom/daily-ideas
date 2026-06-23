import AVFoundation

/// Offline pronunciation via `AVSpeechSynthesizer`. No network required.
@MainActor
final class SpeechManager: ObservableObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()

    /// Tracks whether speech is currently in progress (for UI feedback).
    @Published private(set) var isSpeaking = false

    private init() {}

    /// Speak a phrase in the given BCP-47 locale at the given normalized rate.
    /// - Parameters:
    ///   - text: the target-language text.
    ///   - localeIdentifier: e.g. "es-ES".
    ///   - rate: 0.0...1.0 normalized; mapped into the supported AVSpeech range.
    func speak(_ text: String, localeIdentifier: String, rate: Double) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        configureAudioSession()

        let utterance = AVSpeechUtterance(string: trimmed)
        if let voice = AVSpeechSynthesisVoice(language: localeIdentifier) {
            utterance.voice = voice
        }
        // Map normalized 0...1 onto a comfortable slice of the valid range.
        let minR = AVSpeechUtteranceMinimumSpeechRate
        let maxR = AVSpeechUtteranceMaximumSpeechRate
        let clamped = max(0, min(1, Float(rate)))
        utterance.rate = minR + (maxR - minR) * clamped * 0.7
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.05

        isSpeaking = true
        synthesizer.speak(utterance)
        // Reset the flag shortly after; AVSpeech has no simple async completion here,
        // so we approximate with a timer proportional to length.
        let seconds = max(0.6, Double(trimmed.count) * 0.07)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.isSpeaking = self?.synthesizer.isSpeaking ?? false
        }
    }

    /// Stop any in-progress speech.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        // Use playback so audio works even with the silent switch on, but stay
        // resilient: ignore failures rather than crashing on user paths.
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
    }
}
