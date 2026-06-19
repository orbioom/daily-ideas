import Foundation
import SwiftUI

extension Double {
    /// Returns a percentage string, e.g. 0.85 -> "85%"
    var percentString: String {
        "\(Int(self * 100))%"
    }

    /// Clamps the value between min and max
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension Date {
    /// Returns true if this date is the same calendar day as another date
    func isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }

    /// Returns true if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns short weekday string (Mon, Tue, etc.)
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
}

extension Array where Element == KanaCard {
    /// Returns cards filtered by card type
    func filtered(by type: CardType?) -> [KanaCard] {
        guard let type = type else { return self }
        return filter { $0.cardType == type }
    }

    /// Returns only due cards
    var dueCards: [KanaCard] {
        filter { $0.isDue }
    }

    /// Returns only learned cards
    var learnedCards: [KanaCard] {
        filter { $0.isLearned }
    }

    /// Returns overall accuracy across all cards that have been reviewed
    var overallAccuracy: Double {
        let reviewed = filter { $0.totalReviews > 0 }
        guard !reviewed.isEmpty else { return 0 }
        let totalCorrect = reviewed.reduce(0) { $0 + $1.correctReviews }
        let totalReviews = reviewed.reduce(0) { $0 + $1.totalReviews }
        guard totalReviews > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalReviews)
    }
}
