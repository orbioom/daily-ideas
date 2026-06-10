import Foundation
import SwiftData
import SwiftUI

/// One day's gratitude practice. A structured morning ritual (three gratitudes
/// + an intention) and an evening reflection (three good things + one thing that
/// could improve), with an end-of-day mood. One row per calendar day.
@Model
final class GratitudeDay {
    @Attribute(.unique) var dayKey: Int            // yyyymmdd, one entry per day
    var date: Date                                 // start of that day
    var morningGratitudes: [String]
    var dailyIntention: String
    var eveningWins: [String]
    var improvement: String
    var mood: Int                                  // 0 = unset, 1...5
    var morningDone: Bool
    var eveningDone: Bool
    var createdAt: Date
    var updatedAt: Date

    init(date: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let c = cal.dateComponents([.year, .month, .day], from: start)
        self.dayKey = (c.year ?? 2026) * 10_000 + (c.month ?? 1) * 100 + (c.day ?? 1)
        self.date = start
        self.morningGratitudes = ["", "", ""]
        self.dailyIntention = ""
        self.eveningWins = ["", "", ""]
        self.improvement = ""
        self.mood = 0
        self.morningDone = false
        self.eveningDone = false
        self.createdAt = .now
        self.updatedAt = .now
    }

    var filledGratitudes: [String] {
        morningGratitudes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    var filledWins: [String] {
        eveningWins.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    var hasAnyContent: Bool {
        !filledGratitudes.isEmpty || !filledWins.isEmpty
            || !dailyIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !improvement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var wordCount: Int {
        let all = (morningGratitudes + eveningWins + [dailyIntention, improvement]).joined(separator: " ")
        return all.split(whereSeparator: { $0 == " " || $0 == "\n" }).count
    }
}

enum Mood: Int, CaseIterable, Identifiable {
    case awful = 1, low, okay, good, great
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .awful: return "Rough"
        case .low: return "Low"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        }
    }
    var emoji: String {
        switch self {
        case .awful: return "😔"
        case .low: return "😕"
        case .okay: return "😌"
        case .good: return "🙂"
        case .great: return "😄"
        }
    }
    var color: Color {
        switch self {
        case .awful: return Brand.dynamic(0xB1604E, 0xE08A78)
        case .low: return Brand.dynamic(0xC0913E, 0xE0B86A)
        case .okay: return Brand.dynamic(0x9A8F5E, 0xC9BE86)
        case .good: return Brand.dynamic(0x5E9A86, 0x86C79A)
        case .great: return Brand.dynamic(0x3E9E78, 0x5EF0B0)
        }
    }
}
