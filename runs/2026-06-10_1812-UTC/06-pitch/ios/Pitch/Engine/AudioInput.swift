import Foundation
import AVFoundation

/// Captures microphone audio and runs pitch detection, publishing the detected
/// frequency and clarity on the main thread.
final class AudioInput: ObservableObject {
    @Published var frequency: Double = 0
    @Published var clarity: Double = 0
    @Published var isRunning = false
    @Published var permission: AVAudioApplication.recordPermission = AVAudioApplication.shared.recordPermission

    private let engine = AVAudioEngine()
    private var detector = PitchDetector()
    private var tapInstalled = false

    func refreshPermission() {
        permission = AVAudioApplication.shared.recordPermission
    }

    func requestPermission() async -> Bool {
        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { ok in continuation.resume(returning: ok) }
        }
        await MainActor.run { self.permission = AVAudioApplication.shared.recordPermission }
        return granted
    }

    func start() {
        guard !isRunning else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: [])
        try? session.setActive(true, options: [])

        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }
        detector.sampleRate = format.sampleRate
        let localDetector = detector

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let frames = Int(buffer.frameLength)
            guard frames > 0, let channel = buffer.floatChannelData?[0] else { return }
            let samples = Array(UnsafeBufferPointer(start: channel, count: frames))
            if let result = localDetector.detect(samples) {
                DispatchQueue.main.async {
                    self.frequency = result.frequency
                    self.clarity = result.clarity
                }
            } else {
                DispatchQueue.main.async { self.clarity = max(0, self.clarity - 0.34) }
            }
        }
        tapInstalled = true
        engine.prepare()
        do {
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    func stop() {
        guard isRunning || tapInstalled else { return }
        engine.inputNode.removeTap(onBus: 0)
        tapInstalled = false
        engine.stop()
        isRunning = false
        clarity = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
