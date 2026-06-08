import Foundation

/// Pure pregnancy math: gestational age, trimester, progress, IOM weight-gain
/// ranges, kick-counting, and contraction (5-1-1) analysis. No UI, no storage.
enum PregnancyEngine {

    static let term = 280   // days of a full-term pregnancy

    // MARK: - Gestational age

    struct Age {
        let totalDays: Int
        var weeks: Int { max(0, totalDays / 7) }
        var days: Int { max(0, totalDays % 7) }
        var displayWeek: Int { min(max(weeks, 0), 42) }
    }

    static func age(dueDate: Date, on day: Date = .now, calendar: Calendar = .current) -> Age {
        let start = calendar.date(byAdding: .day, value: -term, to: dueDate) ?? dueDate
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: start),
                                           to: calendar.startOfDay(for: day)).day ?? 0
        return Age(totalDays: days)
    }

    static func daysRemaining(dueDate: Date, on day: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day],
                                from: calendar.startOfDay(for: day),
                                to: calendar.startOfDay(for: dueDate)).day ?? 0
    }

    /// 0...1 of the full term completed.
    static func progress(dueDate: Date, on day: Date = .now) -> Double {
        let a = age(dueDate: dueDate, on: day)
        return min(max(Double(a.totalDays) / Double(term), 0), 1)
    }

    static func trimester(week: Int) -> Int {
        switch week {
        case ..<14: return 1
        case 14..<28: return 2
        default: return 3
        }
    }

    static func trimesterName(_ t: Int) -> String {
        switch t {
        case 1: return "First trimester"
        case 2: return "Second trimester"
        default: return "Third trimester"
        }
    }

    // MARK: - Weight gain (Institute of Medicine guidelines)

    enum BMICategory: String {
        case underweight = "Underweight"
        case normal = "Healthy"
        case overweight = "Overweight"
        case obese = "Higher weight"
    }

    static func bmi(weightKg: Double, heightCm: Double) -> Double? {
        guard weightKg > 0, heightCm > 0 else { return nil }
        let m = heightCm / 100
        return weightKg / (m * m)
    }

    static func category(forBMI bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case 18.5..<25: return .normal
        case 25..<30: return .overweight
        default: return .obese
        }
    }

    /// Total recommended gain (kg) over a singleton pregnancy by BMI category.
    static func recommendedTotalGainKg(category: BMICategory, isMultiple: Bool) -> ClosedRange<Double> {
        if isMultiple {
            switch category {
            case .underweight: return 17...25  // limited guidance; use normal-multiple band
            case .normal:      return 17...25
            case .overweight:  return 14...23
            case .obese:       return 11...19
            }
        }
        switch category {
        case .underweight: return 12.5...18
        case .normal:      return 11.5...16
        case .overweight:  return 7...11.5
        case .obese:       return 5...9
        }
    }

    /// Expected gain so far for a given week, distributing total gain across
    /// term (gain mostly happens after the first trimester).
    static func expectedGainSoFar(week: Int, total: ClosedRange<Double>) -> ClosedRange<Double> {
        let w = Double(min(max(week, 0), 40))
        // ~2 kg by end of T1, then linear to term.
        let fraction: Double
        if w <= 13 {
            fraction = (w / 13.0) * 0.13
        } else {
            fraction = 0.13 + ((w - 13.0) / 27.0) * 0.87
        }
        return (total.lowerBound * fraction)...(total.upperBound * fraction)
    }

    // MARK: - Kick counting

    struct KickStatus {
        let count: Int
        let target: Int
        let elapsedSeconds: Int
        var reachedTarget: Bool { count >= target }
        var remaining: Int { max(0, target - count) }
    }

    // MARK: - Contractions (5-1-1 rule)

    struct ContractionAnalysis {
        let averageFrequencyMinutes: Double   // time between starts
        let averageDurationSeconds: Double
        let count: Int
        /// 5-1-1: ~5 min apart, ~1 min long, for ~1 hour — a common "go in" guideline.
        let meets511: Bool
    }

    /// Analyze the most recent contractions (expects ascending by start).
    static func analyze(_ contractions: [Contraction], window: Int = 6) -> ContractionAnalysis? {
        let sorted = contractions.sorted { $0.start < $1.start }
        guard sorted.count >= 2 else { return nil }
        let recent = Array(sorted.suffix(window))
        var gaps: [Double] = []
        for i in 1..<recent.count {
            gaps.append(recent[i].start.timeIntervalSince(recent[i - 1].start) / 60.0)
        }
        let avgFreq = gaps.isEmpty ? 0 : gaps.reduce(0, +) / Double(gaps.count)
        let avgDur = recent.reduce(0.0) { $0 + Double($1.durationSeconds) } / Double(recent.count)
        let spanMinutes = sorted.last!.start.timeIntervalSince(sorted.first!.start) / 60.0
        let meets = avgFreq > 0 && avgFreq <= 5.5 && avgDur >= 45 && spanMinutes >= 55
        return ContractionAnalysis(averageFrequencyMinutes: avgFreq,
                                   averageDurationSeconds: avgDur,
                                   count: sorted.count,
                                   meets511: meets)
    }

    // MARK: - Formatting

    static func ageString(_ age: Age) -> String {
        "\(age.weeks)w \(age.days)d"
    }
}
