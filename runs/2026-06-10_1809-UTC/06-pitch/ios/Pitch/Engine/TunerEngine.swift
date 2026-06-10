import Foundation
import AVFoundation

/// Captures microphone audio and reports the detected pitch. All processing is
/// on-device; nothing is recorded or stored.
@Observable
final class TunerEngine {
    enum Permission { case undetermined, granted, denied }

    private let engine = AVAudioEngine()
    private let analysisQueue = DispatchQueue(label: "com.orbioom.pitch.analysis")
    private var installed = false

    var permission: Permission = .undetermined
    var isRunning = false
    var a4: Double = 440

    // Published readings.
    var reading: NoteReading?
    var amplitude: Float = 0
    var displayCents: Double = 0      // smoothed for the needle
    var hasSignal = false

    private var centsHistory: [Double] = []
    private var lastMidi: Int?
    private var silentFrames = 0

    init() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: permission = .granted
        case .denied: permission = .denied
        default: permission = .undetermined
        }
    }

    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.permission = granted ? .granted : .denied
                completion(granted)
            }
        }
    }

    func start() {
        guard !isRunning else { return }
        guard permission == .granted else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true, options: [])

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            let sampleRate = format.sampleRate
            guard sampleRate > 0 else { return }
            let detector = PitchDetector(sampleRate: sampleRate)

            if !installed {
                input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
                    self?.process(buffer, detector: detector)
                }
                installed = true
            }
            engine.prepare()
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    func stop() {
        guard isRunning else { return }
        if installed { engine.inputNode.removeTap(onBus: 0); installed = false }
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        isRunning = false
        hasSignal = false
        reading = nil
    }

    private func process(_ buffer: AVAudioPCMBuffer, detector: PitchDetector) {
        guard let channel = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }
        let samples = Array(UnsafeBufferPointer(start: channel, count: count))
        let a4 = self.a4

        analysisQueue.async { [weak self] in
            guard let self else { return }
            let result = detector.detect(samples)
            DispatchQueue.main.async {
                self.update(result: result, a4: a4)
            }
        }
    }

    private func update(result: (frequency: Double, amplitude: Float)?, a4: Double) {
        guard let result, let r = NoteMath.reading(frequency: result.frequency, a4: a4) else {
            silentFrames += 1
            if silentFrames > 3 { hasSignal = false; amplitude = 0 }
            return
        }
        silentFrames = 0
        amplitude = result.amplitude
        hasSignal = true

        // Stabilize note across small fluctuations.
        if lastMidi == nil || abs(r.midi - (lastMidi ?? r.midi)) >= 1 {
            centsHistory.removeAll()
        }
        lastMidi = r.midi
        reading = r

        centsHistory.append(r.cents)
        if centsHistory.count > 6 { centsHistory.removeFirst() }
        displayCents = centsHistory.reduce(0, +) / Double(centsHistory.count)
    }
}
