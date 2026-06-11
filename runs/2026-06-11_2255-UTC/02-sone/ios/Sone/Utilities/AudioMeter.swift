import Foundation
import AVFoundation
import Observation

/// Live microphone level meter. Audio is analyzed buffer-by-buffer on the
/// tap thread and reduced to a single RMS level — nothing is recorded or
/// written to disk.
@Observable
final class AudioMeter {
    enum State: Equatable {
        case idle
        case requestingPermission
        case running
        case denied
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Latest estimated sound pressure level in dB.
    private(set) var currentDB: Double = 0
    /// Rolling trace for the live sparkline (~5 Hz, last 60 s).
    private(set) var trace: [Double] = []

    // Live min/avg/max since the meter started (or stats were reset).
    private(set) var minDB: Double = .infinity
    private(set) var maxDB: Double = 0
    private var energySum: Double = 0
    private var energyCount: Int = 0

    // Recording state (a "measurement" the user explicitly captures).
    private(set) var isRecording = false
    private(set) var recordingStart: Date?
    private(set) var recordingSamples: [Double] = []
    private(set) var recordingDose: Double = 0

    /// Calibration offset applied to digital full-scale RMS, user adjustable.
    var calibrationOffset: Double = 100

    private let engine = AVAudioEngine()
    private var lastSampleAt: Date = .distantPast

    var averageDB: Double {
        guard energyCount > 0 else { return 0 }
        return 10 * log10(energySum / Double(energyCount))
    }

    // MARK: - Lifecycle

    func start() {
        guard state != .running, state != .requestingPermission else { return }
        state = .requestingPermission
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            beginRunning()
        case .denied:
            state = .denied
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted { self.beginRunning() } else { self.state = .denied }
                }
            }
        @unknown default:
            state = .denied
        }
    }

    func stop() {
        if engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        state = .idle
    }

    func resetStats() {
        minDB = .infinity
        maxDB = 0
        energySum = 0
        energyCount = 0
    }

    private func beginRunning() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true)

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                state = .failed("No usable microphone input was found.")
                return
            }
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
                self?.process(buffer: buffer)
            }
            engine.prepare()
            try engine.start()
            resetStats()
            state = .running
        } catch {
            state = .failed("The microphone could not be started: \(error.localizedDescription)")
        }
    }

    // MARK: - Processing

    private func process(buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?[0] else { return }
        let n = Int(buffer.frameLength)
        guard n > 0 else { return }
        var sum: Float = 0
        for i in 0..<n {
            let v = channel[i]
            sum += v * v
        }
        let rms = Double(sqrt(sum / Float(n)))
        let dbfs = 20 * log10(max(rms, 1e-7))
        let db = min(130, max(20, dbfs + calibrationOffset))

        DispatchQueue.main.async { [weak self] in
            self?.ingest(db)
        }
    }

    private func ingest(_ db: Double) {
        // Light smoothing so the needle reads like an SLM, not a strobe.
        currentDB = currentDB == 0 ? db : currentDB * 0.6 + db * 0.4
        minDB = min(minDB, currentDB)
        maxDB = max(maxDB, currentDB)
        energySum += pow(10, currentDB / 10)
        energyCount += 1

        let now = Date.now
        if now.timeIntervalSince(lastSampleAt) >= 0.2 {
            lastSampleAt = now
            trace.append(currentDB)
            if trace.count > 300 { trace.removeFirst(trace.count - 300) }
            if isRecording {
                recordingSamples.append(currentDB)
                recordingDose += NoiseMath.dose(seconds: 0.2, at: currentDB)
            }
        }
    }

    // MARK: - Measurements

    func beginRecording() {
        guard state == .running, !isRecording else { return }
        recordingStart = .now
        recordingSamples = []
        recordingDose = 0
        isRecording = true
    }

    /// Stops the measurement and returns a summary, or `nil` if it was too
    /// short to be meaningful.
    func endRecording() -> (start: Date, duration: TimeInterval, avg: Double,
                            min: Double, max: Double, dose: Double, samples: [Double])? {
        guard isRecording, let start = recordingStart else { return nil }
        isRecording = false
        recordingStart = nil
        let duration = Date.now.timeIntervalSince(start)
        guard duration >= 2, !recordingSamples.isEmpty else { return nil }

        let avg = NoiseMath.energyAverage(recordingSamples)
        let lo = recordingSamples.min() ?? 0
        let hi = recordingSamples.max() ?? 0

        // Downsample the trace to at most 360 points for storage.
        let stride = max(1, recordingSamples.count / 360)
        var stored: [Double] = []
        var i = 0
        while i < recordingSamples.count {
            let chunk = recordingSamples[i..<min(i + stride, recordingSamples.count)]
            stored.append(chunk.reduce(0, +) / Double(chunk.count))
            i += stride
        }
        return (start, duration, avg, lo, hi, recordingDose, stored)
    }
}
