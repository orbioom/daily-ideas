import SwiftData
import Foundation

enum PRCategory: String, CaseIterable, Codable {
    case m500 = "500m"
    case m1000 = "1,000m"
    case m2000 = "2,000m"
    case m5000 = "5,000m"
    case m10000 = "10,000m"
    case min20 = "20 min"
    case min30 = "30 min"
    case min60 = "60 min"

    var isDistance: Bool {
        switch self {
        case .min20, .min30, .min60: return false
        default: return true
        }
    }

    var targetMeters: Int? {
        switch self {
        case .m500: return 500
        case .m1000: return 1000
        case .m2000: return 2000
        case .m5000: return 5000
        case .m10000: return 10000
        default: return nil
        }
    }

    var targetSeconds: Int? {
        switch self {
        case .min20: return 1200
        case .min30: return 1800
        case .min60: return 3600
        default: return nil
        }
    }
}

@Model
final class RowPR {
    var id: UUID
    var categoryRaw: String
    var value: Int
    var achievedDate: Date
    var workoutID: UUID?

    init(category: PRCategory, value: Int, achievedDate: Date = Date(), workoutID: UUID? = nil) {
        self.id = UUID()
        self.categoryRaw = category.rawValue
        self.value = value
        self.achievedDate = achievedDate
        self.workoutID = workoutID
    }

    var category: PRCategory {
        get { PRCategory(rawValue: categoryRaw) ?? .m2000 }
        set { categoryRaw = newValue.rawValue }
    }

    var displayValue: String {
        if category.isDistance {
            return RowEngine.formatDuration(value)
        } else {
            return String(format: "%.1f km", Double(value) / 1000)
        }
    }
}
