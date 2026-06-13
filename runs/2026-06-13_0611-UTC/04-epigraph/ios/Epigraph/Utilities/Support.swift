import SwiftUI
import UIKit

enum Haptics {
    static var enabled = true
    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func soft() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var scheme: ColorScheme? {
        switch self { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
}

/// Tracks the daily-review streak in UserDefaults.
enum ReviewStreak {
    static func record() {
        let d = UserDefaults.standard
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let lastRaw = d.object(forKey: "lastReviewDay") as? Double ?? 0
        let last = Date(timeIntervalSince1970: lastRaw)
        let lastDay = cal.startOfDay(for: last)
        if lastRaw > 0, cal.isDate(lastDay, inSameDayAs: today) {
            // already counted today
        } else {
            var streak = d.integer(forKey: "reviewStreak")
            if lastRaw > 0, let diff = cal.dateComponents([.day], from: lastDay, to: today).day, diff == 1 {
                streak += 1
            } else {
                streak = 1
            }
            d.set(streak, forKey: "reviewStreak")
            d.set(today.timeIntervalSince1970, forKey: "lastReviewDay")
        }
        d.set(d.integer(forKey: "totalReviews") + 1, forKey: "totalReviews")
    }

    static var current: Int {
        let d = UserDefaults.standard
        let lastRaw = d.object(forKey: "lastReviewDay") as? Double ?? 0
        guard lastRaw > 0 else { return 0 }
        let cal = Calendar.current
        let lastDay = cal.startOfDay(for: Date(timeIntervalSince1970: lastRaw))
        let today = cal.startOfDay(for: .now)
        let diff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 99
        return diff <= 1 ? d.integer(forKey: "reviewStreak") : 0
    }

    static var reviewedToday: Bool {
        let d = UserDefaults.standard
        let lastRaw = d.object(forKey: "lastReviewDay") as? Double ?? 0
        guard lastRaw > 0 else { return false }
        return Calendar.current.isDateInToday(Date(timeIntervalSince1970: lastRaw))
    }
}
