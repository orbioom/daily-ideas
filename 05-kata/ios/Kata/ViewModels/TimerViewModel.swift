import Foundation
import SwiftUI
import Observation

enum TimerState {
    case idle, countdown, running, paused, done
}

@Observable
final class TimerViewModel {
    var state: TimerState = .idle
    var elapsed: Int = 0
    var countdown: Int = 3
    var timeCap: Int = 0
    var mode: WODType = .forTime

    private var timer: Timer?

    var displayTime: String {
        switch state {
        case .countdown: return "\(countdown)"
        case .idle: return "GO"
        default:
            if timeCap > 0 && mode == .forTime {
                let remaining = max(0, timeCap - elapsed)
                return formatTime(remaining)
            }
            return formatTime(elapsed)
        }
    }

    var isCountingDown: Bool { state == .countdown }
    var isRunning: Bool { state == .running }
    var isPaused: Bool { state == .paused }

    var timeCapReached: Bool {
        timeCap > 0 && elapsed >= timeCap
    }

    func start(timeCap: Int = 0, mode: WODType = .forTime) {
        self.timeCap = timeCap
        self.mode = mode
        state = .countdown
        countdown = 3
        elapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        state = .done
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        elapsed = 0
        countdown = 3
    }

    private func tick() {
        switch state {
        case .countdown:
            countdown -= 1
            if countdown <= 0 {
                state = .running
            }
        case .running:
            elapsed += 1
            if timeCapReached {
                stop()
            }
        default: break
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
