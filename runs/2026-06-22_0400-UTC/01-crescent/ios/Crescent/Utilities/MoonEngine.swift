import Foundation

enum MoonPhase: String, CaseIterable, Identifiable {
    case newMoon        = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter   = "First Quarter"
    case waxingGibbous  = "Waxing Gibbous"
    case fullMoon       = "Full Moon"
    case waningGibbous  = "Waning Gibbous"
    case lastQuarter    = "Last Quarter"
    case waningCrescent = "Waning Crescent"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .newMoon:        return "🌑"
        case .waxingCrescent: return "🌒"
        case .firstQuarter:   return "🌓"
        case .waxingGibbous:  return "🌔"
        case .fullMoon:       return "🌕"
        case .waningGibbous:  return "🌖"
        case .lastQuarter:    return "🌗"
        case .waningCrescent: return "🌘"
        }
    }

    var energy: String {
        switch self {
        case .newMoon:        return "New Beginnings"
        case .waxingCrescent: return "Setting Intentions"
        case .firstQuarter:   return "Taking Action"
        case .waxingGibbous:  return "Refinement"
        case .fullMoon:       return "Culmination & Release"
        case .waningGibbous:  return "Gratitude"
        case .lastQuarter:    return "Letting Go"
        case .waningCrescent: return "Rest & Reflection"
        }
    }

    var affirmation: String {
        switch self {
        case .newMoon:        return "I plant seeds of possibility."
        case .waxingCrescent: return "I nurture my intentions with care."
        case .firstQuarter:   return "I act with purpose and courage."
        case .waxingGibbous:  return "I refine and adjust my path."
        case .fullMoon:       return "I release what no longer serves me."
        case .waningGibbous:  return "I give thanks for all that I have."
        case .lastQuarter:    return "I forgive and let go freely."
        case .waningCrescent: return "I rest and prepare for renewal."
        }
    }

    var ritualSuggestion: String {
        switch self {
        case .newMoon:
            return "Write 3 intentions for this lunar cycle. Light a candle and meditate on new beginnings."
        case .waxingCrescent:
            return "Review your intentions. Take one small action toward each goal today."
        case .firstQuarter:
            return "Identify any obstacles to your goals. Journal about how to overcome them."
        case .waxingGibbous:
            return "Fine-tune your plans. What small adjustments will bring you closer to your vision?"
        case .fullMoon:
            return "Write what you want to release on paper, then safely burn or bury it. Celebrate your progress."
        case .waningGibbous:
            return "Make a gratitude list of 10 things. Share your abundance with someone."
        case .lastQuarter:
            return "Forgive yourself and others. Journal about lessons learned this cycle."
        case .waningCrescent:
            return "Rest. Sleep, meditate, or spend quiet time in nature. Prepare for renewal."
        }
    }

    var isNewOrFull: Bool { self == .newMoon || self == .fullMoon }
}

enum MoonEngine {
    private static let synodicMonth: Double = 29.53059 * 86_400
    private static let knownNewMoon: Date = {
        var c = DateComponents()
        c.year = 2024; c.month = 1; c.day = 11
        c.hour = 11; c.minute = 57
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c) ?? Date()
    }()

    static func phaseAngle(for date: Date = .now) -> Double {
        let elapsed = date.timeIntervalSince(knownNewMoon)
        let raw = (elapsed / synodicMonth).truncatingRemainder(dividingBy: 1.0)
        return raw < 0 ? raw + 1.0 : raw
    }

    static func illumination(for date: Date = .now) -> Double {
        (1 - cos(2 * .pi * phaseAngle(for: date))) / 2
    }

    static func moonPhase(for date: Date = .now) -> MoonPhase {
        let a = phaseAngle(for: date)
        switch a {
        case 0..<0.034:  return .newMoon
        case 0.034..<0.233: return .waxingCrescent
        case 0.233..<0.284: return .firstQuarter
        case 0.284..<0.483: return .waxingGibbous
        case 0.483..<0.517: return .fullMoon
        case 0.517..<0.716: return .waningGibbous
        case 0.716..<0.767: return .lastQuarter
        default:            return .waningCrescent
        }
    }

    static func nextNewMoon(after date: Date = .now) -> Date {
        let a = phaseAngle(for: date)
        let remaining = 1.0 - a
        return date.addingTimeInterval(remaining * synodicMonth)
    }

    static func nextFullMoon(after date: Date = .now) -> Date {
        let a = phaseAngle(for: date)
        let diff = 0.5 - a
        let remaining = diff < 0 ? diff + 1.0 : diff
        return date.addingTimeInterval(remaining * synodicMonth)
    }

    static func daysUntil(_ target: Date, from date: Date = .now) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: date, to: target).day ?? 0)
    }

    static func calendarPhases(for month: Date) -> [(date: Date, phase: MoonPhase)] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: month),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: month)) else { return [] }
        return range.compactMap { day -> (Date, MoonPhase)? in
            guard let d = cal.date(byAdding: .day, value: day - 1, to: start) else { return nil }
            return (d, moonPhase(for: d))
        }
    }
}
