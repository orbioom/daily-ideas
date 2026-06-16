import Foundation
import AVFoundation

/// Wraps AVSpeechSynthesizer for read-aloud (Pro). @MainActor since it touches
/// audio session + UI-bound state.
@MainActor
@Observable
final class SpeechManager {
    private let synthesizer = AVSpeechSynthesizer()

    /// Whether speech is currently playing (best-effort UI flag).
    private(set) var isSpeaking: Bool = false

    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Configure the audio session defensively; ignore failures (read-aloud
        // is a nice-to-have, never a crash path).
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Non-fatal: proceed; the synthesizer may still produce output.
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}
