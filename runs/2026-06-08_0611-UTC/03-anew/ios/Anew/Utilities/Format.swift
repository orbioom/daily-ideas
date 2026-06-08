import Foundation

enum Format {

    // MARK: - Currency

    static func currency(_ amount: Double, symbol: String = "$") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(symbol)\(formatted)"
    }

    // MARK: - Duration text (verbose)

    static func duration(days: Int, hours: Int, minutes: Int, seconds: Int) -> String {
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    // MARK: - Live counter segments (zero-padded)

    static func paddedDays(_ days: Int) -> String {
        days >= 1000 ? "\(days)" : String(format: "%03d", days)
    }

    static func paddedTwo(_ value: Int) -> String {
        String(format: "%02d", value)
    }

    // MARK: - Relative date

    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Short date

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Units avoided

    static func unitsAvoided(_ count: Double, label: String) -> String {
        let formatted = count >= 10000
            ? String(format: "%.0f", count)
            : String(format: "%.1f", count)
        return "\(formatted) \(label)"
    }

    // MARK: - Mood emoji

    static func moodEmoji(_ mood: Int) -> String {
        switch mood {
        case 1: return "😣"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }

    static func moodLabel(_ mood: Int) -> String {
        switch mood {
        case 1: return "Struggling"
        case 2: return "Difficult"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Neutral"
        }
    }
}
