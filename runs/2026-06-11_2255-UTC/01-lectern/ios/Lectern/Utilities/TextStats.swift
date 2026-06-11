import Foundation

enum TextStats {
    static func wordCount(_ text: String) -> Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    /// Estimated spoken duration at a given pace.
    static func estimatedDuration(words: Int, wordsPerMinute: Double) -> TimeInterval {
        guard wordsPerMinute > 0 else { return 0 }
        return Double(words) / wordsPerMinute * 60
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded()))
        let m = s / 60
        let r = s % 60
        if m >= 60 {
            return String(format: "%d:%02d:%02d", m / 60, m % 60, r)
        }
        return String(format: "%d:%02d", m, r)
    }

    static func formatMinutes(_ seconds: TimeInterval) -> String {
        let m = seconds / 60
        if m < 1 { return "\(Int(seconds.rounded()))s" }
        if m < 60 { return String(format: "%.0f min", m) }
        return String(format: "%.1f h", m / 60)
    }
}
