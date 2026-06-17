import Foundation

enum DateFmt {
    static let medium: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let short: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static func medium(_ date: Date) -> String { medium.string(from: date) }
    static func short(_ date: Date) -> String { short.string(from: date) }
}

/// Helpers shared by views for turning canonical values into themed display.
enum GoalProgress {
    /// Computes progress 0...1 toward `goal` starting from `start`, using the
    /// `current` value. Works for both increasing and decreasing goals.
    static func fraction(start: Double, current: Double, goal: Double) -> Double {
        let totalNeeded = goal - start
        guard abs(totalNeeded) > 0.0001 else {
            return current == goal ? 1 : 0
        }
        let done = current - start
        let frac = done / totalNeeded
        return min(max(frac, 0), 1)
    }
}
