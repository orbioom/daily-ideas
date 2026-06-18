import SwiftUI

/// Tracks how many practice puzzles a free player has started today, to enforce the daily cap.
/// Stored in @AppStorage so it survives relaunch; resets when the date key changes.
@MainActor final class PracticeLedger: ObservableObject {
    @AppStorage("practiceDateKey") private var practiceDateKey = ""
    @AppStorage("practiceCountToday") private var practiceCountToday = 0

    func startedToday() -> Int {
        rollIfNeeded()
        return practiceCountToday
    }

    func remaining(isPro: Bool) -> Int {
        if isPro { return Int.max }
        rollIfNeeded()
        return max(0, ProStore.freePracticePerDay - practiceCountToday)
    }

    func canStart(isPro: Bool) -> Bool {
        isPro || remaining(isPro: false) > 0
    }

    func recordStart() {
        rollIfNeeded()
        practiceCountToday += 1
    }

    private func rollIfNeeded() {
        let today = DateKey.today
        if practiceDateKey != today {
            practiceDateKey = today
            practiceCountToday = 0
        }
    }
}
