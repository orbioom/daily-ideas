import SwiftUI

// MARK: - Preference enums

enum CollectionSort: String, CaseIterable, Identifiable {
    case recent
    case name
    case rating
    case plays
    case weight

    var id: String { rawValue }
    var label: String {
        switch self {
        case .recent: return "Recently Added"
        case .name: return "Name"
        case .rating: return "Rating"
        case .plays: return "Most Played"
        case .weight: return "Weight"
        }
    }
}

enum WinnerRule: String, CaseIterable, Identifiable {
    case highestScore
    case lowestScore
    case manual

    var id: String { rawValue }
    var label: String {
        switch self {
        case .highestScore: return "Highest Score Wins"
        case .lowestScore: return "Lowest Score Wins"
        case .manual: return "Mark Manually"
        }
    }
}

enum WeightDisplay: String, CaseIterable, Identifiable {
    case numbers
    case words

    var id: String { rawValue }
    var label: String {
        switch self {
        case .numbers: return "Numbers (2.7)"
        case .words: return "Words (Medium)"
        }
    }

    /// Render a weight value per the chosen display mode.
    func render(_ weight: Double) -> String {
        switch self {
        case .numbers:
            return String(format: "%.1f", weight)
        case .words:
            switch weight {
            case ..<1.5: return "Light"
            case ..<2.5: return "Light-Med"
            case ..<3.5: return "Medium"
            case ..<4.2: return "Med-Heavy"
            default: return "Heavy"
            }
        }
    }
}

enum DurationUnit: String, CaseIterable, Identifiable {
    case minutes
    case hoursMinutes

    var id: String { rawValue }
    var label: String {
        switch self {
        case .minutes: return "Minutes (90m)"
        case .hoursMinutes: return "Hours & Minutes (1h 30m)"
        }
    }

    func render(_ minutes: Int) -> String {
        guard minutes > 0 else { return "—" }
        switch self {
        case .minutes:
            return "\(minutes)m"
        case .hoursMinutes:
            let h = minutes / 60
            let m = minutes % 60
            if h == 0 { return "\(m)m" }
            if m == 0 { return "\(h)h" }
            return "\(h)h \(m)m"
        }
    }
}

// MARK: - AppSettings

final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("defaultCollectionSort") var defaultCollectionSortRaw: String = CollectionSort.recent.rawValue
    @AppStorage("winnerRule") var winnerRuleRaw: String = WinnerRule.highestScore.rawValue
    @AppStorage("showWeightAs") var showWeightAsRaw: String = WeightDisplay.numbers.rawValue
    @AppStorage("durationUnit") var durationUnitRaw: String = DurationUnit.minutes.rawValue

    var defaultCollectionSort: CollectionSort {
        get { CollectionSort(rawValue: defaultCollectionSortRaw) ?? .recent }
        set { defaultCollectionSortRaw = newValue.rawValue }
    }
    var winnerRule: WinnerRule {
        get { WinnerRule(rawValue: winnerRuleRaw) ?? .highestScore }
        set { winnerRuleRaw = newValue.rawValue }
    }
    var showWeightAs: WeightDisplay {
        get { WeightDisplay(rawValue: showWeightAsRaw) ?? .numbers }
        set { showWeightAsRaw = newValue.rawValue }
    }
    var durationUnit: DurationUnit {
        get { DurationUnit(rawValue: durationUnitRaw) ?? .minutes }
        set { durationUnitRaw = newValue.rawValue }
    }
}
