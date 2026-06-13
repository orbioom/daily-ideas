import AVFoundation

/// Thin wrapper over AVSpeechSynthesizer for spoken coaching cues.
final class Speaker {
    private let synth = AVSpeechSynthesizer()

    func configureSession() {
        // Duck other audio (music/podcasts) while cues play, then restore.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers, .mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func say(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.5
        u.pitchMultiplier = 1.0
        u.volume = 1.0
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }
}
