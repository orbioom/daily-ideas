import Foundation
import SwiftData

/// A logged practice session — either a fretboard note drill or a chord-change
/// drill. One model covers both via `kind`; metrics are interpreted per kind.
@Model
final class PracticeSession {
    var date: Date
    var kindRaw: String
    var durationSeconds: Int
    /// Primary metric: drill score (correct answers) or changes-per-minute.
    var primaryMetric: Int
    /// Secondary metric: questions asked (fretboard) or total changes (changes).
    var secondaryMetric: Int
    /// A short label, e.g. "Standard · 0–5" or "C ⇄ G".
    var label: String

    init(date: Date = .now, kind: Kind, durationSeconds: Int,
         primaryMetric: Int, secondaryMetric: Int, label: String) {
        self.date = date
        self.kindRaw = kind.rawValue
        self.durationSeconds = durationSeconds
        self.primaryMetric = primaryMetric
        self.secondaryMetric = secondaryMetric
        self.label = label
    }

    enum Kind: String, Codable, CaseIterable {
        case fretboard
        case changes
    }

    var kind: Kind { Kind(rawValue: kindRaw) ?? .fretboard }

    /// Accuracy for fretboard drills (0...1); 0 for change drills.
    var accuracy: Double {
        guard kind == .fretboard, secondaryMetric > 0 else { return 0 }
        return Double(primaryMetric) / Double(secondaryMetric)
    }
}

/// Aggregates over logged sessions: streaks, totals, and per-kind bests.
struct PracticeStats {
    let totalSessions: Int
    let totalMinutes: Int
    let currentStreak: Int
    let longestStreak: Int
    let bestCPM: Int
    let bestAccuracy: Double

    static func from(_ sessions: [PracticeSession]) -> PracticeStats {
        let totalSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }
        let cpm = sessions.filter { $0.kind == .changes }.map(\.primaryMetric).max() ?? 0
        let acc = sessions.filter { $0.kind == .fretboard }.map(\.accuracy).max() ?? 0

        // Streak over distinct practice days.
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) }).sorted()
        var longest = 0, run = 0
        var prev: Date?
        for d in days {
            if let p = prev, cal.dateComponents([.day], from: p, to: d).day == 1 { run += 1 }
            else { run = 1 }
            longest = max(longest, run)
            prev = d
        }
        var current = 0
        if let last = days.last {
            let gap = cal.dateComponents([.day], from: last, to: cal.startOfDay(for: .now)).day ?? 99
            if gap <= 1 {
                current = 1
                var cursor = last
                while let p = cal.date(byAdding: .day, value: -1, to: cursor),
                      days.contains(p) { current += 1; cursor = p }
            }
        }

        return PracticeStats(
            totalSessions: sessions.count,
            totalMinutes: totalSeconds / 60,
            currentStreak: current,
            longestStreak: longest,
            bestCPM: cpm,
            bestAccuracy: acc)
    }
}
