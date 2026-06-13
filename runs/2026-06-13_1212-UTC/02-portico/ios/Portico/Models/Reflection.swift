import Foundation
import SwiftData

/// A single completed reflection — either a morning preparation or an evening
/// review. One model covers both via `kind`; fields are interpreted per kind.
/// At most one reflection exists per (day, kind).
@Model
final class Reflection {
    var date: Date
    var kindRaw: String
    /// Identifies the prompt set used (so an edited reflection re-loads its prompts).
    var promptKey: String
    /// The learner's answers, aligned 1:1 with the prompt set.
    var responses: [String]
    /// Evening mood, 1...5. Meaningless (0) for morning reflections.
    var mood: Int
    /// The cardinal virtue chosen as a focus (morning) or reviewed (evening).
    var virtueRaw: String

    init(date: Date = .now, kind: Kind, promptKey: String,
         responses: [String], mood: Int = 0, virtue: Virtue = .wisdom) {
        self.date = date
        self.kindRaw = kind.rawValue
        self.promptKey = promptKey
        self.responses = responses
        self.mood = mood
        self.virtueRaw = virtue.rawValue
    }

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case morning
        case evening
        var id: String { rawValue }

        var title: String { self == .morning ? "Morning preparation" : "Evening reflection" }
        var icon: String { self == .morning ? "sunrise.fill" : "moon.stars.fill" }
        var verb: String { self == .morning ? "Prepare" : "Reflect" }
    }

    var kind: Kind { Kind(rawValue: kindRaw) ?? .morning }
    var virtue: Virtue {
        get { Virtue(rawValue: virtueRaw) ?? .wisdom }
        set { virtueRaw = newValue.rawValue }
    }

    /// A short one-line summary built from the first non-empty answer.
    var summary: String {
        let first = responses.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        return first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "—"
    }
}

/// Aggregates over logged reflections: streaks, totals, per-kind counts, mood.
struct PracticeStats {
    let totalReflections: Int
    let morningCount: Int
    let eveningCount: Int
    let currentStreak: Int
    let longestStreak: Int
    let avgMood: Double
    /// Last-30 evening reflections as (date, mood) for the mood-trend chart.
    let moodByDay: [MoodPoint]

    struct MoodPoint: Identifiable {
        let id = UUID()
        let date: Date
        let mood: Int
    }

    static func from(_ reflections: [Reflection]) -> PracticeStats {
        let mornings = reflections.filter { $0.kind == .morning }
        let evenings = reflections.filter { $0.kind == .evening }

        let moods = evenings.map(\.mood).filter { $0 > 0 }
        let avg = moods.isEmpty ? 0 : Double(moods.reduce(0, +)) / Double(moods.count)

        let trend = evenings
            .filter { $0.mood > 0 }
            .sorted { $0.date < $1.date }
            .suffix(30)
            .map { MoodPoint(date: $0.date, mood: $0.mood) }

        // Streak over distinct reflection days (any kind counts toward the day).
        let cal = Calendar.current
        let days = Set(reflections.map { cal.startOfDay(for: $0.date) }).sorted()
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
            totalReflections: reflections.count,
            morningCount: mornings.count,
            eveningCount: evenings.count,
            currentStreak: current,
            longestStreak: longest,
            avgMood: avg,
            moodByDay: Array(trend))
    }
}
