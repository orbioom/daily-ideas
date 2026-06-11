import AVFoundation
import Speech
import SwiftUI
import SwiftData

enum RecordingState {
    case idle, recording, paused, processing, done
}

@Observable
class RecorderViewModel {
    private(set) var state: RecordingState = .idle
    private(set) var elapsedSeconds: Double = 0
    private(set) var meterLevel: Float = 0       // 0–1 normalized for waveform
    private(set) var waveformSamples: [Float] = Array(repeating: 0, count: 60)
    private(set) var transcript: String = ""
    private(set) var transcriptConfidence: Float = 0

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timerTask: Task<Void, Never>?
    private var meterTask: Task<Void, Never>?
    private var currentFilename: String = ""
    private var accumulatedSeconds: Double = 0
    private var sessionStart = Date()

    var onEntrySaved: ((VoiceEntry) -> Void)?

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let micOK = await AVAudioApplication.requestRecordPermission()
        guard micOK else { return false }
        let speechOK = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        return speechOK
    }

    // MARK: - Recording

    func startRecording() {
        guard state == .idle || state == .paused else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try? session.setActive(true)

        if currentFilename.isEmpty {
            currentFilename = AudioStore.newFilename()
        }
        let url = AudioStore.url(for: currentFilename)
        recorder = try? AVAudioRecorder(url: url, settings: AudioStore.recordingSettings())
        recorder?.isMeteringEnabled = true
        recorder?.record()
        sessionStart = Date()
        state = .recording
        startTimerAndMeter()
    }

    func pauseRecording() {
        guard state == .recording else { return }
        recorder?.pause()
        accumulatedSeconds += Date().timeIntervalSince(sessionStart)
        timerTask?.cancel(); meterTask?.cancel()
        state = .paused
    }

    func stopAndProcess(modelContext: ModelContext) {
        guard state == .recording || state == .paused else { return }
        if state == .recording { accumulatedSeconds += Date().timeIntervalSince(sessionStart) }
        recorder?.stop()
        timerTask?.cancel(); meterTask?.cancel()
        elapsedSeconds = accumulatedSeconds
        state = .processing
        transcribeAndSave(modelContext: modelContext)
    }

    func discardRecording() {
        recorder?.stop()
        timerTask?.cancel(); meterTask?.cancel()
        if !currentFilename.isEmpty { AudioStore.delete(currentFilename) }
        resetState()
    }

    // MARK: - Transcription

    private func transcribeAndSave(modelContext: ModelContext) {
        let filename = currentFilename
        let duration = accumulatedSeconds
        let url = AudioStore.url(for: filename)

        Task {
            let result = await transcribe(url: url)
            await MainActor.run {
                let entry = VoiceEntry(audioFilename: filename, durationSeconds: duration)
                entry.transcript = result.text
                entry.transcriptConfidence = result.confidence
                entry.title = autoTitle(from: result.text)
                modelContext.insert(entry)
                try? modelContext.save()
                onEntrySaved?(entry)
                transcript = result.text
                state = .done
            }
        }
    }

    private struct TranscriptResult {
        let text: String
        let confidence: Float
    }

    private func transcribe(url: URL) async -> TranscriptResult {
        guard let recognizer = SFSpeechRecognizer(locale: Locale.current),
              recognizer.isAvailable else {
            return TranscriptResult(text: "", confidence: 0)
        }
        let req = SFSpeechURLRecognitionRequest(url: url)
        req.requiresOnDeviceRecognition = true
        req.shouldReportPartialResults = false

        return await withCheckedContinuation { cont in
            var resumed = false
            recognizer.recognitionTask(with: req) { result, error in
                guard !resumed else { return }
                if let r = result, r.isFinal {
                    resumed = true
                    let text = r.bestTranscription.formattedString
                    let conf = r.bestTranscription.segments.map { Float($0.confidence) }.reduce(0, +)
                                / Float(max(1, r.bestTranscription.segments.count))
                    cont.resume(returning: TranscriptResult(text: text, confidence: conf))
                } else if error != nil {
                    resumed = true
                    cont.resume(returning: TranscriptResult(text: "", confidence: 0))
                }
            }
        }
    }

    private func autoTitle(from text: String) -> String {
        let words = text.split(separator: " ").prefix(6).joined(separator: " ")
        return words.isEmpty ? "" : words + (text.split(separator: " ").count > 6 ? "…" : "")
    }

    // MARK: - Playback

    func playEntry(_ filename: String) {
        let url = AudioStore.url(for: filename)
        guard AudioStore.exists(filename) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    func stopPlayback() { player?.stop() }

    // MARK: - Timer & Meter

    private func startTimerAndMeter() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                await MainActor.run {
                    if state == .recording {
                        elapsedSeconds = accumulatedSeconds + Date().timeIntervalSince(sessionStart)
                    }
                }
            }
        }
        meterTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                await MainActor.run {
                    recorder?.updateMeters()
                    let db = recorder?.averagePower(forChannel: 0) ?? -160
                    let normalized = max(0, min(1, (db + 60) / 60))
                    meterLevel = normalized
                    waveformSamples.removeFirst()
                    waveformSamples.append(normalized)
                }
            }
        }
    }

    private func resetState() {
        state = .idle
        elapsedSeconds = 0
        accumulatedSeconds = 0
        currentFilename = ""
        transcript = ""
        waveformSamples = Array(repeating: 0, count: 60)
    }

    var elapsedFormatted: String {
        let t = Int(elapsedSeconds)
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
