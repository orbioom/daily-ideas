import Foundation
import SwiftData

/// A yarn in the user's stash. Yardage totals drive the "enough yarn?" check.
@Model
final class StashYarn {
    var id: UUID = UUID()
    var name: String = ""
    var brand: String = ""
    var fiber: String = ""
    var colorName: String = ""
    var weightRaw: Int = YarnWeight.medium.rawValue
    var skeins: Int = 1
    var yardsPerSkein: Double = 0
    var gramsPerSkein: Double = 0
    var notes: String = ""
    var createdAt: Date = Date()

    init(name: String, brand: String = "", weight: YarnWeight = .medium,
         skeins: Int = 1, yardsPerSkein: Double = 0) {
        self.name = name
        self.brand = brand
        self.weightRaw = weight.rawValue
        self.skeins = max(0, skeins)
        self.yardsPerSkein = max(0, yardsPerSkein)
    }

    var weight: YarnWeight {
        get { YarnWeight(rawValue: weightRaw) ?? .medium }
        set { weightRaw = newValue.rawValue }
    }
    var totalYards: Double { Double(max(0, skeins)) * max(0, yardsPerSkein) }
    var totalGrams: Double { Double(max(0, skeins)) * max(0, gramsPerSkein) }
}
