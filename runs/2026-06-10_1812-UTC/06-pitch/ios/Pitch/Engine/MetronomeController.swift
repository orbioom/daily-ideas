import Foundation
import Combine

/// Drives metronome timing with a high-resolution dispatch timer, firing clicks
/// through a ToneEngine and publishing the current beat for the visual pulse.
final class MetronomeController: ObservableObject {
    @Published var bpm: Int = 100 { didSet { if isRunning { restartTimer() } } }
    @Published var beatsPerBar: Int = 4
    @Published var subdivision: Int = 1 { didSet { if isRunning { restartTimer() } } }
    @Published var accentFirst: Bool = true
    @Published private(set) var isRunning = false
    @Published private(set) var currentBeat: Int = -1

    private let tone: ToneEngine
    private var timer: DispatchSourceTimer?
    private var tickIndex = 0
    private var tapTimes: [Date] = []

    init(tone: ToneEngine) { self.tone = tone }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        tickIndex = 0
        currentBeat = -1
        restartTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
        currentBeat = -1
    }

    func toggle() { isRunning ? stop() : start() }

    private func restartTimer() {
        timer?.cancel()
        let interval = 60.0 / (Double(max(20, bpm)) * Double(max(1, subdivision)))
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "metronome", qos: .userInteractive))
        t.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(1))
        t.setEventHandler { [weak self] in self?.tick() }
        timer = t
        t.resume()
    }

    private func tick() {
        let sub = max(1, subdivision)
        let isMainBeat = tickIndex % sub == 0
        let beatNumber = (tickIndex / sub) % max(1, beatsPerBar)
        if isMainBeat {
            // Accent the downbeat (beat 1) when enabled; other beats click normally.
            tone.click(accent: accentFirst && beatNumber == 0)
            DispatchQueue.main.async { self.currentBeat = beatNumber }
        } else {
            // Subdivisions get a softer click (handled by ToneEngine as non-accent).
            tone.click(accent: false)
        }
        tickIndex += 1
    }

    // MARK: - Tap tempo

    func tap() {
        let now = Date()
        tapTimes.append(now)
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 3 }
        guard tapTimes.count >= 2 else { return }
        var intervals: [Double] = []
        for i in 1..<tapTimes.count {
            intervals.append(tapTimes[i].timeIntervalSince(tapTimes[i - 1]))
        }
        let avg = intervals.reduce(0, +) / Double(intervals.count)
        guard avg > 0 else { return }
        let computed = Int((60.0 / avg).rounded())
        bpm = min(300, max(20, computed))
    }
}
