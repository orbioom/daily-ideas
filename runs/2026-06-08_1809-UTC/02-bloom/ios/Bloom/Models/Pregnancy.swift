import Foundation
import SwiftData

/// The single active pregnancy record. Holds the anchor (due date) plus the
/// optional pre-pregnancy details used to compute a healthy weight-gain range.
@Model
final class Pregnancy {
    var babyName: String
    var dueDate: Date
    /// Pre-pregnancy weight in kilograms (0 if unknown).
    var prePregnancyWeightKg: Double
    /// Height in centimeters (0 if unknown).
    var heightCm: Double
    var isMultiple: Bool          // twins/multiples — widens gain range
    var createdAt: Date

    init(babyName: String = "",
         dueDate: Date,
         prePregnancyWeightKg: Double = 0,
         heightCm: Double = 0,
         isMultiple: Bool = false) {
        self.babyName = babyName
        self.dueDate = dueDate
        self.prePregnancyWeightKg = prePregnancyWeightKg
        self.heightCm = heightCm
        self.isMultiple = isMultiple
        self.createdAt = .now
    }

    /// Estimated conception / start of gestation (due date minus 280 days).
    var gestationStart: Date {
        Calendar.current.date(byAdding: .day, value: -280, to: dueDate) ?? dueDate
    }
}
