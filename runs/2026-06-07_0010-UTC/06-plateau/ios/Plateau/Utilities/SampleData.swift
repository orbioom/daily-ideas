import Foundation
import SwiftData

enum SampleData {
    static func seed(into context: ModelContext) {
        let cal = Calendar.current

        // One cook currently in progress (started a while ago).
        let active = makeCook(name: "Chicken breast", category: "Poultry", shape: .slab,
                              thickness: 35, bathC: 60, start: .fridge, logs: 7,
                              state: .cooking,
                              startedAt: cal.date(byAdding: .minute, value: -40, to: .now) ?? .now)
        context.insert(active)

        // Completed history.
        let history: [(String, String, FoodShape, Double, Double, StartState, Double, Int, Bool, Int)] = [
            ("Beef steak", "Beef", .slab, 25, 54.5, .fridge, 6.5, 5, true, 2),
            ("Salmon", "Seafood", .slab, 25, 50, .fridge, 0, 4, false, 5),
            ("Pork chop", "Pork", .slab, 30, 58, .fridge, 6.5, 4, false, 9),
            ("Onsen egg", "Egg", .sphere, 42, 63, .fridge, 0, 5, true, 12),
            ("Chicken thigh", "Poultry", .slab, 30, 65, .fridge, 7, 4, false, 16),
            ("Beef roast", "Beef", .cylinder, 70, 56, .fridge, 6.5, 5, true, 22)
        ]
        for (i, h) in history.enumerated() {
            let c = makeCook(name: h.0, category: h.1, shape: h.2, thickness: h.3, bathC: h.4,
                             start: h.5, logs: h.6, state: .done,
                             startedAt: cal.date(byAdding: .day, value: -h.9, to: .now) ?? .now)
            c.rating = h.7; c.isFavorite = h.8
            if i == 0 { c.notes = "Perfect crust after a screaming-hot sear." }
            context.insert(c)
        }

        try? context.save()
    }

    private static func makeCook(name: String, category: String, shape: FoodShape,
                                 thickness: Double, bathC: Double, start: StartState,
                                 logs: Double, state: CookState, startedAt: Date) -> Cook {
        let plan = PlateauMath.plan(thicknessMM: thickness, shape: shape, bathC: bathC,
                                    startC: start.celsius, logReductions: logs)
        return Cook(foodName: name, category: category, shape: shape, thicknessMM: thickness,
                    bathC: bathC, startState: start, logReductions: logs,
                    comeUpMinutes: plan.comeUpMinutes, pasteurizeMinutes: plan.pasteurizeMinutes,
                    totalMinutes: plan.totalMinutes, startedAt: startedAt, state: state)
    }
}
