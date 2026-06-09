import Foundation

/// Small, dependency-free number/macro formatting helpers shared across views.
enum Format {

    /// A whole-number calorie string, e.g. "420".
    static func kcal(_ value: Double) -> String {
        "\(Int(value.rounded()))"
    }

    /// A gram value rounded to one decimal with a trailing "g", e.g. "12.5 g".
    static func grams(_ value: Double) -> String {
        "\(NutritionEngine.gramsString(value)) g"
    }

    /// A gram value with no unit, e.g. "12.5".
    static func gramsValue(_ value: Double) -> String {
        NutritionEngine.gramsString(value)
    }

    /// A 0…1 fraction as a whole-number percent, e.g. 0.42 -> "42%".
    static func percent(_ fraction: Double) -> String {
        let clamped = fraction.isFinite ? fraction : 0
        return "\(Int((clamped * 100).rounded()))%"
    }

    /// A quantity typed by the user, dropping a redundant ".0".
    static func quantity(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.2f", value)
    }

    /// "1 serving" / "4 servings".
    static func servings(_ count: Int) -> String {
        count == 1 ? "1 serving" : "\(count) servings"
    }

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}
