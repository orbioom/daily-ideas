import AVFoundation

final class SpeechManager {
    // Shared synthesizer – must be retained at class level
    private static let synthesizer = AVSpeechSynthesizer()

    /// Speak the given text using the specified BCP-47 language tag.
    /// Defaults to Mandarin (zh-CN).
    static func speak(_ text: String, language: String = "zh-CN") {
        // Cancel any currently playing speech before starting new
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Ensure audio session is active for playback
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        synthesizer.speak(utterance)
    }
}
