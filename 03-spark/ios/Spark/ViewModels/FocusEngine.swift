import Foundation
import SwiftUI
import Combine

@Observable
final class FocusTimerEngine {
    var isRunning: Bool = false
    var isPaused: Bool = false
    var remainingSeconds: Int = 25 * 60
    var totalSeconds: Int = 25 * 60
    var elapsedSeconds: Int = 0

    private var startDate: Date?
    private var pausedElapsed: Int = 0
    private var timer: Timer?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(elapsedSeconds) / Double(totalSeconds)
    }

    var progressColor: Color {
        if progress < 0.5 { return SparkTheme.electricBlue }
        if progress < 0.8 { return SparkTheme.focusGreen }
        return SparkTheme.amber
    }

    var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var warningState: FocusWarning {
        let remaining = Double(remainingSeconds)
        let total = Double(totalSeconds)
        if remaining <= 60 && total > 60 { return .almostDone }
        if remaining <= 300 && total > 300 { return .fiveMinutes }
        return .normal
    }

    enum FocusWarning {
        case normal, fiveMinutes, almostDone
    }

    func start(minutes: Int) {
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        elapsedSeconds = 0
        pausedElapsed = 0
        startDate = Date()
        isRunning = true
        isPaused = false
        scheduleTimer()
    }

    func pause() {
        isPaused = true
        pausedElapsed = elapsedSeconds
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard isPaused else { return }
        startDate = Date()
        isPaused = false
        scheduleTimer()
    }

    func stop() -> Int {
        let elapsed = elapsedSeconds
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        return elapsed
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let newElapsed = pausedElapsed + Int(Date().timeIntervalSince(startDate ?? Date()))
            self.elapsedSeconds = newElapsed
            self.remainingSeconds = max(0, self.totalSeconds - newElapsed)
            if self.remainingSeconds <= 0 {
                self.isRunning = false
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    deinit { timer?.invalidate() }
}

@Observable
final class FocusStatsEngine {
    func totalFocusMinutes(_ sessions: [FocusSession]) -> Int {
        sessions.reduce(0) { $0 + $1.actualMinutes }
    }

    func completionRate(_ sessions: [FocusSession]) -> Double {
        guard !sessions.isEmpty else { return 0 }
        let completed = sessions.filter { $0.wasCompleted }.count
        return Double(completed) / Double(sessions.count)
    }

    func streakDays(_ sessions: [FocusSession]) -> Int {
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        var streak = 0
        var current = cal.startOfDay(for: Date())
        for day in days {
            if day == current {
                streak += 1
                current = cal.date(byAdding: .day, value: -1, to: current) ?? current
            } else { break }
        }
        return streak
    }

    func weeklyMinutes(_ sessions: [FocusSession]) -> [(day: String, minutes: Int)] {
        let cal = Calendar.current
        let now = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        var result: [(String, Int)] = []
        for i in (0..<7).reversed() {
            guard let day = cal.date(byAdding: .day, value: -i, to: now) else { continue }
            let mins = sessions.filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.actualMinutes }
            result.append((fmt.string(from: day), mins))
        }
        return result
    }

    func categoryBreakdown(_ sessions: [FocusSession]) -> [(category: TaskCategory, minutes: Int)] {
        Dictionary(grouping: sessions, by: { $0.category })
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.actualMinutes }) }
            .sorted { $0.1 > $1.1 }
    }
}

enum SparkSettings {
    static let onboardingDone = "spark_onboarding_v1"
    static let defaultDuration = "spark_default_duration"
    static let warningHaptics = "spark_warning_haptics"
    static let keepScreenOn = "spark_keep_screen_on"
    static let transitionWarning = "spark_transition_warning"
}
