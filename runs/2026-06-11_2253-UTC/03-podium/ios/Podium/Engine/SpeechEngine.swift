import Foundation
import AVFAudio
import Speech
import Observation

/// Live recording + on-device transcription. AVAudioEngine taps the mic,
/// SFSpeechRecognizer transcribes continuously; partial results drive the
/// live pace/filler readouts. Nothing is uploaded when on-device
/// recognition is available (and we request it explicitly).
@Observable
final class SpeechEngine {

    enum State: Equatable {
        case idle
        case requesting
        case denied(String)
        case recording(startedAt: Date)
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var liveTranscript: String = ""
    private(set) var liveWordCount = 0
    private(set) var liveFillerCount = 0
    private(set) var liveWPM: Double = 0

    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var startDate = Date()

    var isRecording: Bool {
        if case .recording = state { return true }
        return false
    }

    func start() {
        guard !isRecording else { return }
        state = .requesting
        // 1) Microphone permission.
        switch AVAudioApplication.shared.recordPermission {
        case .denied:
            state = .denied("Microphone access is off. Enable it in Settings → Podium.")
            return
        case .granted:
            requestSpeechAuth()
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted { self.requestSpeechAuth() }
                    else { self.state = .denied("Microphone access is off. Enable it in Settings → Podium.") }
                }
            }
        @unknown default:
            state = .denied("Microphone access is unavailable.")
        }
    }

    private func requestSpeechAuth() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            begin()
        case .denied, .restricted:
            state = .denied("Speech recognition is off. Enable it in Settings → Podium so transcripts can be analyzed on-device.")
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized { self.begin() }
                    else { self.state = .denied("Speech recognition permission was not granted.") }
                }
            }
        @unknown default:
            state = .denied("Speech recognition is unavailable.")
        }
    }

    private func begin() {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable else {
            state = .failed("Speech recognition isn't available on this device right now.")
            return
        }
        self.recognizer = recognizer
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }
            self.request = request

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0 else {
                state = .failed("No microphone input is available.")
                return
            }
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()

            startDate = Date()
            liveTranscript = ""
            liveWordCount = 0
            liveFillerCount = 0
            liveWPM = 0
            state = .recording(startedAt: startDate)

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                DispatchQueue.main.async {
                    if let result {
                        self.ingest(transcript: result.bestTranscription.formattedString)
                    }
                    if error != nil, self.isRecording {
                        // Recognition hiccup mid-session: keep what we have; the
                        // user can stop and save. Restarting risks losing text.
                    }
                }
            }
        } catch {
            cleanupAudio()
            state = .failed("Couldn't start recording: \(error.localizedDescription)")
        }
    }

    private func ingest(transcript: String) {
        guard isRecording else { return }
        liveTranscript = transcript
        let tokens = SpeechAnalyzer.tokenize(transcript)
        liveWordCount = tokens.count
        liveFillerCount = SpeechAnalyzer.countFillers(tokens: tokens).total
        let minutes = max(Date().timeIntervalSince(startDate) / 60, 1.0 / 60)
        liveWPM = Double(liveWordCount) / minutes
    }

    /// Stop and hand back the final transcript + duration.
    func finish() -> (transcript: String, duration: TimeInterval)? {
        guard case .recording(let started) = state else { return nil }
        let duration = Date().timeIntervalSince(started)
        let transcript = liveTranscript
        cleanupAudio()
        state = .idle
        return (transcript, duration)
    }

    func cancel() {
        cleanupAudio()
        state = .idle
    }

    func acknowledgeError() {
        state = .idle
    }

    private func cleanupAudio() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
