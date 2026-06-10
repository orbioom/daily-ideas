import Foundation
import AVFoundation

/// A metronome that synthesizes its click on-device and schedules beats with a
/// dispatch timer. Accents the first beat of the bar.
@Observable
final class Metronome {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.orbioom.pitch.metronome", qos: .userInteractive)

    var isRunning = false
    var bpm: Int = 100
    var beatsPerBar: Int = 4
    var accentFirst: Bool = true
    var currentBeat: Int = 0       // 0-based within the bar; -1 when stopped
    private var beatIndex = 0

    init() { setup() }

    private func setup() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        accentBuffer = makeClick(frequency: 1500, format: format)
        normalBuffer = makeClick(frequency: 1000, format: format)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    /// A short enveloped sine burst.
    private func makeClick(frequency: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration = 0.045
        let frames = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        let twoPi = 2.0 * Double.pi
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            // Fast exponential decay envelope.
            let env = exp(-t * 55.0)
            channel[i] = Float(sin(twoPi * frequency * t) * env) * 0.6
        }
        return buffer
    }

    func start() {
        guard !isRunning else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
            if !engine.isRunning { engine.prepare(); try engine.start() }
            player.play()
            beatIndex = 0
            isRunning = true
            schedule()
        } catch {
            isRunning = false
        }
    }

    func stop() {
        guard isRunning else { return }
        timer?.cancel(); timer = nil
        player.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        isRunning = false
        currentBeat = -1
    }

    func toggle() { isRunning ? stop() : start() }

    /// Set the tempo and, if running, reschedule the click timer to match.
    func setTempo(_ newBPM: Int) {
        bpm = max(40, min(240, newBPM))
        if isRunning { reschedule() }
    }

    private func schedule() {
        timer?.cancel()
        let interval = 60.0 / Double(max(20, min(300, bpm)))
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(1))
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        timer = t
    }

    private func reschedule() {
        guard isRunning else { return }
        schedule()
    }

    private func tick() {
        let beatInBar = beatIndex % max(1, beatsPerBar)
        let isAccent = accentFirst && beatInBar == 0
        if let buffer = isAccent ? accentBuffer : normalBuffer {
            player.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
        }
        beatIndex += 1
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentBeat = beatInBar
        }
    }

    /// Tap-tempo: feed timestamps, return the derived BPM when enough taps exist.
    static func bpm(fromIntervals intervals: [TimeInterval]) -> Int? {
        let valid = intervals.filter { $0 > 0.2 && $0 < 2.0 }
        guard valid.count >= 2 else { return nil }
        let avg = valid.reduce(0, +) / Double(valid.count)
        return Int((60.0 / avg).rounded())
    }
}
