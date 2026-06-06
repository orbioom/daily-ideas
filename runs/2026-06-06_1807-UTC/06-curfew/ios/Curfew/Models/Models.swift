import Foundation
import SwiftData

enum DrinkCategory: String, Codable, CaseIterable, Identifiable {
    case coffee = "Coffee", espresso = "Espresso", tea = "Tea", energy = "Energy"
    case soda = "Soda", supplement = "Supplement", other = "Other"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .coffee: return "cup.and.saucer"; case .espresso: return "mug"; case .tea: return "leaf"
        case .energy: return "bolt"; case .soda: return "waterbottle"; case .supplement: return "pill"
        case .other: return "drop"
        }
    }
}

/// A reusable drink template the user can quick-add from.
@Model
final class CaffeineSource {
    var name: String
    var mg: Double
    var categoryRaw: String
    var serving: String
    var favorite: Bool

    init(name: String, mg: Double, category: DrinkCategory = .coffee,
         serving: String = "", favorite: Bool = false) {
        self.name = name; self.mg = max(0, mg); self.categoryRaw = category.rawValue
        self.serving = serving; self.favorite = favorite
    }
    var category: DrinkCategory {
        get { DrinkCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

/// A logged consumption. Name and mg are snapshotted at log time so editing a
/// source later never rewrites history.
@Model
final class Intake {
    var name: String
    var mg: Double
    var time: Date
    var categoryRaw: String

    init(name: String, mg: Double, time: Date = .now, category: DrinkCategory = .coffee) {
        self.name = name; self.mg = max(0, mg); self.time = time; self.categoryRaw = category.rawValue
    }
    var category: DrinkCategory {
        get { DrinkCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    var dose: CaffeineMath.Dose { .init(time: time, mg: mg) }
}
