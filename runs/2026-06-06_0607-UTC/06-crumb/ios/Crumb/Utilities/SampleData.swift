import Foundation
import SwiftData

/// Real, on-brand seed content so a first launch is a populated, working app — not a void.
/// Inserted once (gated by SettingsStore.hasSeeded) and reused by "Reset to sample" in
/// Settings. Always inserts into an empty store only. Every formula uses true-to-life
/// baker's percentages so the engine produces sensible figures out of the box.
enum SampleData {

    static func insert(into context: ModelContext) {
        let country = insertCountrySourdough(into: context)
        insertBaguette(into: context)
        insertFocaccia(into: context)
        insertWholeWheat(into: context)
        insertBakes(for: country, into: context)
        insertStarter(into: context)
    }

    /// Remove every formula, bake, and starter (cascades clear their children).
    static func clear(_ context: ModelContext) throws {
        for f in try context.fetch(FetchDescriptor<Formula>()) { context.delete(f) }
        for b in try context.fetch(FetchDescriptor<Bake>()) { context.delete(b) }
        for s in try context.fetch(FetchDescriptor<Starter>()) { context.delete(s) }
    }

    // MARK: - Formula builders

    private static func add(_ formula: Formula, name: String, role: Role,
                            percent: Double, levainHydration: Double = 100,
                            order: Int, context: ModelContext) {
        let ing = Ingredient(name: name, role: role, percent: percent,
                             levainHydration: levainHydration,
                             createdAt: Date(timeIntervalSince1970: 1_700_000_000 + Double(order)))
        ing.formula = formula
        context.insert(ing)
    }

    @discardableResult
    private static func insertCountrySourdough(into context: ModelContext) -> Formula {
        let f = Formula(name: "Classic Country Sourdough",
                        notes: "An everyday 75% hydration boule with a touch of whole wheat. Open, custardy crumb; deep, blistered crust.",
                        style: .sourdough)
        context.insert(f)
        add(f, name: "Bread flour", role: .flour, percent: 90, order: 0, context: context)
        add(f, name: "Whole wheat flour", role: .flour, percent: 10, order: 1, context: context)
        add(f, name: "Water", role: .water, percent: 72, order: 2, context: context)
        add(f, name: "Stiff levain", role: .levain, percent: 20, levainHydration: 100, order: 3, context: context)
        add(f, name: "Sea salt", role: .salt, percent: 2, order: 4, context: context)
        return f
    }

    private static func insertBaguette(into context: ModelContext) {
        let f = Formula(name: "Sourdough Baguette",
                        notes: "Lean, crackly baguettes at 70% hydration. A long cold bulk builds flavour and a thin, shattering crust.",
                        style: .baguette)
        context.insert(f)
        add(f, name: "T65 bread flour", role: .flour, percent: 100, order: 0, context: context)
        add(f, name: "Water", role: .water, percent: 68, order: 1, context: context)
        add(f, name: "Levain", role: .levain, percent: 15, levainHydration: 100, order: 2, context: context)
        add(f, name: "Sea salt", role: .salt, percent: 2, order: 3, context: context)
    }

    private static func insertFocaccia(into context: ModelContext) {
        let f = Formula(name: "Olive Oil Focaccia",
                        notes: "A high-hydration (82%) pan focaccia, dimpled and pooled with olive oil, finished with flaky salt.",
                        style: .focaccia)
        context.insert(f)
        add(f, name: "Bread flour", role: .flour, percent: 100, order: 0, context: context)
        add(f, name: "Water", role: .water, percent: 80, order: 1, context: context)
        add(f, name: "Levain", role: .levain, percent: 20, levainHydration: 100, order: 2, context: context)
        add(f, name: "Extra-virgin olive oil", role: .other, percent: 6, order: 3, context: context)
        add(f, name: "Sea salt", role: .salt, percent: 2.2, order: 4, context: context)
    }

    private static func insertWholeWheat(into context: ModelContext) {
        let f = Formula(name: "100% Whole Wheat Pan Loaf",
                        notes: "A soft, sliceable wholemeal sandwich loaf at 80% hydration with honey and butter for tenderness.",
                        style: .wholeGrain)
        context.insert(f)
        add(f, name: "Whole wheat flour", role: .flour, percent: 100, order: 0, context: context)
        add(f, name: "Water", role: .water, percent: 76, order: 1, context: context)
        add(f, name: "Levain", role: .levain, percent: 18, levainHydration: 100, order: 2, context: context)
        add(f, name: "Honey", role: .other, percent: 4, order: 3, context: context)
        add(f, name: "Butter", role: .other, percent: 3, order: 4, context: context)
        add(f, name: "Sea salt", role: .salt, percent: 2, order: 5, context: context)
    }

    // MARK: - Bake builders

    private static func step(_ bake: Bake, order: Int, kind: StepKind,
                             minutes: Int, detail: String = "", context: ModelContext) {
        let s = BakeStep(order: order, kind: kind, plannedMinutes: minutes, detail: detail)
        s.bake = bake
        context.insert(s)
    }

    private static func insertBakes(for formula: Formula, into context: ModelContext) {
        let cal = Calendar.current

        // A completed, rated bake from a few days ago.
        let pastDate = cal.date(byAdding: .day, value: -4, to: .now) ?? .now
        let past = Bake(title: "Saturday boules",
                        date: pastDate,
                        anchorTime: cal.date(bySettingHour: 8, minute: 0, second: 0, of: pastDate) ?? pastDate,
                        schedulesFromFinish: false,
                        targetDoughGrams: 1800,
                        loafCount: 2,
                        notes: "Best ear yet. Slightly under-proofed centre — push bulk 20 min longer next time.",
                        crumbRating: 4,
                        ovenTempC: 245,
                        doughTempC: 25,
                        isComplete: true)
        past.formula = formula
        context.insert(past)
        step(past, order: 0, kind: .autolyse, minutes: 45, detail: "Flour + water only", context: context)
        step(past, order: 1, kind: .mix, minutes: 15, detail: "Add levain and salt", context: context)
        step(past, order: 2, kind: .bulk, minutes: 240, detail: "4 folds, 30 min apart", context: context)
        step(past, order: 3, kind: .preshape, minutes: 20, context: context)
        step(past, order: 4, kind: .shape, minutes: 15, context: context)
        step(past, order: 5, kind: .coldProof, minutes: 720, detail: "Fridge, seam up", context: context)
        step(past, order: 6, kind: .bake, minutes: 45, detail: "20 covered, 25 uncovered", context: context)
        step(past, order: 7, kind: .cool, minutes: 90, context: context)

        // An upcoming planned bake, scheduled backward from a target dinner finish.
        let futureDate = cal.date(byAdding: .day, value: 1, to: .now) ?? .now
        let finish = cal.date(bySettingHour: 18, minute: 30, second: 0, of: futureDate) ?? futureDate
        let upcoming = Bake(title: "Sunday dinner loaf",
                            date: futureDate,
                            anchorTime: finish,
                            schedulesFromFinish: true,
                            targetDoughGrams: 900,
                            loafCount: 1,
                            notes: "",
                            crumbRating: 0,
                            ovenTempC: 245,
                            doughTempC: .nan,
                            isComplete: false)
        upcoming.formula = formula
        context.insert(upcoming)
        step(upcoming, order: 0, kind: .autolyse, minutes: 40, context: context)
        step(upcoming, order: 1, kind: .mix, minutes: 15, context: context)
        step(upcoming, order: 2, kind: .bulk, minutes: 270, detail: "Warm kitchen", context: context)
        step(upcoming, order: 3, kind: .shape, minutes: 15, context: context)
        step(upcoming, order: 4, kind: .proof, minutes: 120, context: context)
        step(upcoming, order: 5, kind: .bake, minutes: 45, context: context)
    }

    // MARK: - Starter

    private static func insertStarter(into context: ModelContext) {
        let starter = Starter(name: "Bubbles",
                              flourType: "50/50 bread & rye",
                              notes: "Kept on the counter at ~23°C, fed once daily. Doubles in about 5 hours when happy.")
        context.insert(starter)

        let cal = Calendar.current
        let feedings: [(hoursAgo: Int, s: Double, fl: Double, w: Double, flour: String, note: String)] = [
            (8,  1, 2, 2, "Bread flour", "Morning feed before today's mix."),
            (32, 1, 2, 2, "Bread flour", "Smelled lightly tangy, very active."),
            (56, 1, 1, 1, "Whole rye", "Stiffer rye build to boost activity."),
            (80, 1, 3, 3, "Bread flour", "Bigger build ahead of a baking weekend.")
        ]
        for (i, f) in feedings.enumerated() {
            let date = cal.date(byAdding: .hour, value: -f.hoursAgo, to: .now) ?? .now
            let feeding = Feeding(date: date, starterParts: f.s, flourParts: f.fl,
                                  waterParts: f.w, flourType: f.flour, notes: f.note)
            feeding.starter = starter
            context.insert(feeding)
            _ = i
        }
    }
}
