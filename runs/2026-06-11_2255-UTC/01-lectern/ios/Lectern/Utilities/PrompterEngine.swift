import SwiftUI
import Observation

/// Drives the prompter scroll deterministically from wall-clock time, so the
/// animation stays smooth at any speed and survives speed changes, pauses and
/// drag-seeking without drift.
@Observable
final class PrompterEngine {
    enum Phase: Equatable {
        case ready
        case countingDown
        case playing
        case paused
        case finished
    }

    private(set) var phase: Phase = .ready
    /// Scroll speed in points of script per second.
    private(set) var pointsPerSecond: CGFloat
    /// Total scrollable distance (set once layout is measured).
    var totalDistance: CGFloat = 0

    /// Accumulated playback time in seconds (excludes pauses).
    private var accumulatedTime: TimeInterval = 0
    /// Accumulated scroll distance at the moment playback last (re)started.
    private var accumulatedOffset: CGFloat = 0
    private var playStartDate: Date?

    init(pointsPerSecond: CGFloat) {
        self.pointsPerSecond = max(8, pointsPerSecond)
    }

    // MARK: - Derived state

    func offset(at date: Date) -> CGFloat {
        switch phase {
        case .playing:
            guard let start = playStartDate else { return clamped(accumulatedOffset) }
            let elapsed = CGFloat(date.timeIntervalSince(start))
            return clamped(accumulatedOffset + elapsed * pointsPerSecond)
        case .finished:
            return totalDistance
        default:
            return clamped(accumulatedOffset)
        }
    }

    func elapsedPlayTime(at date: Date) -> TimeInterval {
        if phase == .playing, let start = playStartDate {
            return accumulatedTime + date.timeIntervalSince(start)
        }
        return accumulatedTime
    }

    func progress(at date: Date) -> Double {
        guard totalDistance > 0 else { return 0 }
        return Double(offset(at: date) / totalDistance)
    }

    var remainingSeconds: TimeInterval {
        guard pointsPerSecond > 0 else { return 0 }
        return Double((totalDistance - clamped(accumulatedOffset)) / pointsPerSecond)
    }

    var estimatedTotalSeconds: TimeInterval {
        guard pointsPerSecond > 0 else { return 0 }
        return Double(totalDistance / pointsPerSecond)
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(max(0, value), max(0, totalDistance))
    }

    // MARK: - Transport

    func beginCountdown() {
        guard phase == .ready || phase == .paused || phase == .finished else { return }
        if phase == .finished { accumulatedOffset = 0; accumulatedTime = 0 }
        phase = .countingDown
    }

    func beginPlaying() {
        guard phase == .countingDown || phase == .paused else { return }
        playStartDate = .now
        phase = .playing
    }

    func pause(at date: Date = .now) {
        guard phase == .playing else { return }
        settle(at: date)
        phase = .paused
    }

    func finish(at date: Date = .now) {
        guard phase == .playing else { return }
        settle(at: date)
        accumulatedOffset = totalDistance
        phase = .finished
    }

    func restart() {
        accumulatedOffset = 0
        accumulatedTime = 0
        playStartDate = nil
        phase = .ready
    }

    /// Re-anchor at `date`, then apply a new speed without a visual jump.
    func setSpeed(_ newValue: CGFloat, at date: Date = .now) {
        if phase == .playing { settle(at: date); playStartDate = date }
        pointsPerSecond = max(8, min(400, newValue))
    }

    /// Drag-seek by a delta in points. Pauses playback while seeking.
    func seek(by delta: CGFloat, at date: Date = .now) {
        if phase == .playing { pause(at: date) }
        accumulatedOffset = clamped(accumulatedOffset + delta)
        if phase == .finished, accumulatedOffset < totalDistance { phase = .paused }
    }

    /// Date at which the scroll will reach the end if playback continues
    /// uninterrupted — used to schedule completion.
    func projectedEndDate(from date: Date = .now) -> Date? {
        guard phase == .playing, let start = playStartDate, pointsPerSecond > 0 else { return nil }
        let remaining = totalDistance - accumulatedOffset
        let totalSeconds = Double(remaining / pointsPerSecond)
        return start.addingTimeInterval(totalSeconds).addingTimeInterval(-date.timeIntervalSince(start) * 0)
    }

    private func settle(at date: Date) {
        guard let start = playStartDate else { return }
        let elapsed = date.timeIntervalSince(start)
        accumulatedTime += elapsed
        accumulatedOffset = clamped(accumulatedOffset + CGFloat(elapsed) * pointsPerSecond)
        playStartDate = nil
    }
}
