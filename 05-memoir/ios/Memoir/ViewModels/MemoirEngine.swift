import Foundation
import SwiftUI
import Observation

// MARK: - LifeEra

enum LifeEra: String, CaseIterable, Codable {
    case childhood = "childhood"
    case teen = "teen"
    case youngAdult = "youngAdult"
    case adult = "adult"
    case recent = "recent"
    case reflection = "reflection"

    var displayName: String {
        switch self {
        case .childhood:  return "Childhood"
        case .teen:       return "Teen Years"
        case .youngAdult: return "Young Adult"
        case .adult:      return "Adult Life"
        case .recent:     return "Recent Years"
        case .reflection: return "Reflection"
        }
    }

    var sortOrder: Int {
        switch self {
        case .childhood:  return 0
        case .teen:       return 1
        case .youngAdult: return 2
        case .adult:      return 3
        case .recent:     return 4
        case .reflection: return 5
        }
    }
}

// MARK: - EntryMood

enum EntryMood: String, CaseIterable, Codable {
    case joyful      = "joyful"
    case nostalgic   = "nostalgic"
    case bittersweet = "bittersweet"
    case proud       = "proud"
    case reflective  = "reflective"
    case grateful    = "grateful"

    var displayName: String {
        switch self {
        case .joyful:      return "Joyful"
        case .nostalgic:   return "Nostalgic"
        case .bittersweet: return "Bittersweet"
        case .proud:       return "Proud"
        case .reflective:  return "Reflective"
        case .grateful:    return "Grateful"
        }
    }

    var icon: String {
        switch self {
        case .joyful:      return "sun.max.fill"
        case .nostalgic:   return "clock.arrow.circlepath"
        case .bittersweet: return "cloud.sun.fill"
        case .proud:       return "star.fill"
        case .reflective:  return "moon.stars.fill"
        case .grateful:    return "heart.fill"
        }
    }

    var emoji: String {
        switch self {
        case .joyful:      return "☀️"
        case .nostalgic:   return "🕰️"
        case .bittersweet: return "⛅"
        case .proud:       return "⭐"
        case .reflective:  return "🌙"
        case .grateful:    return "❤️"
        }
    }
}

// MARK: - MemoirSettings

enum MemoirSettings {
    private static let defaults = UserDefaults.standard

    static var onboardingDone: Bool {
        get { defaults.bool(forKey: "onboardingDone") }
        set { defaults.set(newValue, forKey: "onboardingDone") }
    }

    static var wordGoal: Int {
        get {
            let v = defaults.integer(forKey: "wordGoal")
            return v == 0 ? 200 : v
        }
        set { defaults.set(newValue, forKey: "wordGoal") }
    }

    static var defaultEra: LifeEra {
        get {
            let raw = defaults.string(forKey: "defaultEra") ?? LifeEra.reflection.rawValue
            return LifeEra(rawValue: raw) ?? .reflection
        }
        set { defaults.set(newValue.rawValue, forKey: "defaultEra") }
    }

    static var autoSave: Bool {
        get {
            let v = defaults.object(forKey: "autoSave")
            return v == nil ? true : defaults.bool(forKey: "autoSave")
        }
        set { defaults.set(newValue, forKey: "autoSave") }
    }

    static var hapticFeedback: Bool {
        get {
            let v = defaults.object(forKey: "hapticFeedback")
            return v == nil ? true : defaults.bool(forKey: "hapticFeedback")
        }
        set { defaults.set(newValue, forKey: "hapticFeedback") }
    }
}

// MARK: - MemoirEngine

@Observable
final class MemoirEngine {
    var currentPrompt: WritingPrompt?
    var wordGoal: Int = MemoirSettings.wordGoal
    var writingStreak: Int = 0

    func todayPrompt(from prompts: [WritingPrompt]) -> WritingPrompt? {
        // First unused prompt
        if let unused = prompts.first(where: { !$0.isUsed }) {
            return unused
        }
        // All used: return oldest used
        return prompts.sorted { lhs, rhs in
            let lhsDate = lhs.usedDate ?? .distantPast
            let rhsDate = rhs.usedDate ?? .distantPast
            return lhsDate < rhsDate
        }.first
    }

    func streakDays(from entries: [StoryEntry]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Collect unique days with at least one entry
        var entryDays = Set<Date>()
        for entry in entries {
            let day = calendar.startOfDay(for: entry.createdDate)
            entryDays.insert(day)
        }

        // Walk backwards from today, counting consecutive days
        var streak = 0
        var checkDay = today
        while entryDays.contains(checkDay) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = previous
        }
        return streak
    }

    func totalWords(from entries: [StoryEntry]) -> Int {
        entries.reduce(0) { $0 + $1.wordCount }
    }

    func eraBreakdown(from entries: [StoryEntry]) -> [(era: LifeEra, count: Int)] {
        var counts: [LifeEra: Int] = [:]
        for era in LifeEra.allCases { counts[era] = 0 }
        for entry in entries { counts[entry.era, default: 0] += 1 }
        return LifeEra.allCases.map { era in (era: era, count: counts[era] ?? 0) }
    }

    func recentEntries(from entries: [StoryEntry], limit: Int) -> [StoryEntry] {
        Array(entries.sorted { $0.createdDate > $1.createdDate }.prefix(limit))
    }

    func moodBreakdown(from entries: [StoryEntry]) -> [(mood: EntryMood, count: Int)] {
        var counts: [EntryMood: Int] = [:]
        for mood in EntryMood.allCases { counts[mood] = 0 }
        for entry in entries { counts[entry.mood, default: 0] += 1 }
        return EntryMood.allCases.map { mood in (mood: mood, count: counts[mood] ?? 0) }
    }

    func weeklyWordCounts(from entries: [StoryEntry]) -> [(day: String, words: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return (day: "", words: 0)
            }
            let dayLabel = formatter.string(from: day)
            let words = entries
                .filter { calendar.isDate($0.createdDate, inSameDayAs: day) }
                .reduce(0) { $0 + $1.wordCount }
            return (day: dayLabel, words: words)
        }
    }
}
