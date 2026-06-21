import SwiftData
import Foundation

@Model final class SlideRecord {
    var size: Int
    var moves: Int
    var seconds: Double
    var theme: String
    var date: Date
    init(size: Int, moves: Int, seconds: Double, theme: String) {
        self.size = size; self.moves = moves; self.seconds = seconds
        self.theme = theme; self.date = Date()
    }
}

@Model final class SlidePrefs {
    var defaultSize: Int = 4
    var showNumbers: Bool = true
    var hapticsEnabled: Bool = true
    var dailyReminderEnabled: Bool = false
    var isPro: Bool = false
}

@Model final class SlideDailyResult {
    var dateString: String
    var solved: Bool
    var moves: Int
    var seconds: Double
    init(dateString: String, solved: Bool, moves: Int, seconds: Double) {
        self.dateString = dateString; self.solved = solved
        self.moves = moves; self.seconds = seconds
    }
}

@Model final class SlideOnboarding {
    var completed: Bool = false
    init() {}
}
