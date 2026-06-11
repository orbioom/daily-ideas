import Foundation
import AVFAudio
import Observation

/// Drives the overnight microphone session: AVAudioRecorder with metering,
/// a 0.5s sampling loop, live snore detection, and per-minute level history.
/// Audio is written to a temp file that is deleted when the session ends —
/// Timber keeps metrics, never recordings.
@Observable
final class RecorderEngine {

    enum State: Equatable {
        case idle
        case requestingPermission
        case denied
        case monitoring(startedAt: Date)
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var currentDB: Double = -160
    private(set) var threshold: Double = -46
    private(set) var isSnoringNow = false
    private(set) var liveEpisodes: [SnoreDetector.Detected] = []
    private(set) var minuteLevels: [Double] = []

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var detector = SnoreDetector()
    private var startDate = Date()
    private var minuteAccumulator: [Double] = []
    private var fileURL: URL?

    var sensitivity: Double = 14

    var isMonitoring: Bool {
        if case .monitoring = state { return true }
        return false
    }

    func start() {
        guard !isMonitoring else { return }
        state = .requestingPermission
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            beginRecording()
        case .denied:
            state = .denied
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in
                    if granted { self.beginRecording() } else { self.state = .denied }
                }
            }
        @unknown default:
            state = .denied
        }
    }

    private func beginRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("timber-night-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 22050.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue,
            ]
            let rec = try AVAudioRecorder(url: url, settings: settings)
            rec.isMeteringEnabled = true
            guard rec.record() else {
                state = .failed("The microphone could not start. Close other audio apps and try again.")
                return
            }
            recorder = rec
            fileURL = url
            detector = SnoreDetector(sampleInterval: 0.5, sensitivity: sensitivity)
            startDate = Date()
            liveEpisodes = []
            minuteLevels = []
            minuteAccumulator = []
            state = .monitoring(startedAt: startDate)

            let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.sample() }
            }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        } catch {
            state = .failed("Recording could not start: \(error.localizedDescription)")
        }
    }

    private func sample() {
        guard let rec = recorder, isMonitoring else { return }
        rec.updateMeters()
        let db = Double(rec.averagePower(forChannel: 0))
        currentDB = db
        threshold = detector.threshold
        let offset = Date().timeIntervalSince(startDate)
        if let finished = detector.ingest(db: db, at: offset) {
            liveEpisodes.append(finished)
        }
        isSnoringNow = detector.isInEpisode

        // Per-minute average of normalized loudness for the night chart.
        minuteAccumulator.append(normalized(db))
        if minuteAccumulator.count >= 120 { // 120 × 0.5s = 1 minute
            let avg = minuteAccumulator.reduce(0, +) / Double(minuteAccumulator.count)
            minuteLevels.append(avg)
            minuteAccumulator = []
        }
    }

    /// Map dBFS (-70...0) to 0...1 for display.
    func normalized(_ db: Double) -> Double {
        min(max((db + 70) / 70, 0), 1)
    }

    /// Stops monitoring and returns everything needed to persist the night.
    func finish() -> (startedAt: Date, endedAt: Date,
                      episodes: [SnoreDetector.Detected], minuteLevels: [Double])? {
        guard case .monitoring(let started) = state else { return nil }
        timer?.invalidate()
        timer = nil
        let offset = Date().timeIntervalSince(started)
        if let last = detector.flush(at: offset) {
            liveEpisodes.append(last)
        }
        if !minuteAccumulator.isEmpty {
            minuteLevels.append(minuteAccumulator.reduce(0, +) / Double(minuteAccumulator.count))
            minuteAccumulator = []
        }
        recorder?.stop()
        recorder = nil
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
            fileURL = nil
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        let result = (startedAt: started, endedAt: Date(),
                      episodes: liveEpisodes, minuteLevels: minuteLevels)
        state = .idle
        return result
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
            fileURL = nil
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        state = .idle
    }

    func acknowledgeError() {
        state = .idle
    }
}
