import Foundation

/// Formatting utilities — pure functions, no SwiftData, no UI.
enum Format {

    // MARK: - Duration

    /// e.g. "2h 14m" or "45m" or "30s"
    static func duration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    /// Short form e.g. "2h 14m ago"
    static func ago(_ date: Date, now: Date = Date()) -> String {
        let interval = max(0, now.timeIntervalSince(date))
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if total < 60 {
            return "just now"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m ago"
        } else {
            return "\(minutes)m ago"
        }
    }

    // MARK: - Amount

    static func amount(_ ml: Double, useOz: Bool) -> String {
        if useOz {
            let oz = ml / 29.5735
            return String(format: "%.1f oz", oz)
        } else {
            return String(format: "%.0f mL", ml)
        }
    }

    static func mlToOz(_ ml: Double) -> Double {
        ml / 29.5735
    }

    static func ozToMl(_ oz: Double) -> Double {
        oz * 29.5735
    }

    // MARK: - Age

    /// "3 mo 12 d" style age from birthDate to now
    static func age(from birthDate: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day], from: birthDate, to: now)
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0
        if years > 0 {
            return "\(years)y \(months)mo"
        } else if months > 0 {
            return "\(months)mo \(days)d"
        } else {
            return "\(days)d"
        }
    }

    // MARK: - Time

    static func time(_ date: Date, use24h: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = use24h ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    static func weekdayShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // MARK: - Event summary line

    static func eventSummary(_ event: CareEvent, useOz: Bool, use24h: Bool) -> String {
        switch event.kind {
        case .feed:
            var parts: [String] = []
            if let ft = event.feedType { parts.append(ft.label) }
            if let side = event.breastSide, event.feedType == .breast { parts.append(side.label) }
            if let ml = event.amountML, ml > 0 { parts.append(amount(ml, useOz: useOz)) }
            if let e = event.endTime {
                let dur = max(0, e.timeIntervalSince(event.startTime))
                if dur > 0 { parts.append(duration(dur)) }
            }
            return parts.joined(separator: " · ")
        case .sleep:
            if let e = event.endTime {
                let dur = max(0, e.timeIntervalSince(event.startTime))
                return duration(dur)
            }
            return "Ongoing"
        case .diaper:
            return event.diaperType?.label ?? "Diaper"
        case .pump:
            var parts: [String] = []
            if let ml = event.amountML, ml > 0 { parts.append(amount(ml, useOz: useOz)) }
            if let e = event.endTime {
                let dur = max(0, e.timeIntervalSince(event.startTime))
                if dur > 0 { parts.append(duration(dur)) }
            }
            return parts.isEmpty ? "Pump" : parts.joined(separator: " · ")
        case .note:
            return event.note.isEmpty ? "Note" : event.note
        }
    }
}
