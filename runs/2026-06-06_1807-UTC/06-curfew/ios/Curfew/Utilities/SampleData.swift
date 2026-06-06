import Foundation
import SwiftData

/// Seeds a drink catalog and a day of intakes so the curve and stats render.
enum SampleData {
    static func seed(into context: ModelContext) {
        let cal = Calendar.current
        let sources: [(String, Double, DrinkCategory, String, Bool)] = [
            ("Drip Coffee", 95, .coffee, "8 oz mug", true),
            ("Espresso", 63, .espresso, "1 shot", true),
            ("Double Espresso", 126, .espresso, "2 shots", false),
            ("Latte", 126, .coffee, "2 shots + milk", true),
            ("Cold Brew", 200, .coffee, "16 oz", false),
            ("Black Tea", 47, .tea, "1 cup", true),
            ("Green Tea", 28, .tea, "1 cup", false),
            ("Matcha", 70, .tea, "1 serving", false),
            ("Energy Drink", 80, .energy, "8.4 oz can", false),
            ("Cola", 34, .soda, "12 oz can", false),
            ("Pre-workout", 150, .supplement, "1 scoop", false),
        ]
        for s in sources {
            context.insert(CaffeineSource(name: s.0, mg: s.1, category: s.2, serving: s.3, favorite: s.4))
        }

        func at(_ hour: Int, _ minute: Int, daysAgo: Int = 0) -> Date {
            let base = cal.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        // Today
        context.insert(Intake(name: "Drip Coffee", mg: 95, time: at(7, 15), category: .coffee))
        context.insert(Intake(name: "Latte", mg: 126, time: at(10, 30), category: .coffee))
        context.insert(Intake(name: "Black Tea", mg: 47, time: at(14, 0), category: .tea))
        // Yesterday
        context.insert(Intake(name: "Drip Coffee", mg: 95, time: at(8, 0, daysAgo: 1), category: .coffee))
        context.insert(Intake(name: "Cold Brew", mg: 200, time: at(13, 0, daysAgo: 1), category: .coffee))
        context.insert(Intake(name: "Espresso", mg: 63, time: at(16, 30, daysAgo: 1), category: .espresso))
        // Two days ago
        context.insert(Intake(name: "Double Espresso", mg: 126, time: at(9, 0, daysAgo: 2), category: .espresso))
        context.insert(Intake(name: "Energy Drink", mg: 80, time: at(15, 0, daysAgo: 2), category: .energy))

        try? context.save()
    }
}
