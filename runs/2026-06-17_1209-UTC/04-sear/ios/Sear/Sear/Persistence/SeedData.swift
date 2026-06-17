import Foundation
import SwiftData

/// Seeds the rub collection and a realistic cook log on first launch.
/// Idempotent: each part checks a count before inserting, so it is safe to call
/// repeatedly and from the Settings "Load sample data" action.
enum SeedData {

    /// Seed everything that's missing. Safe to call on every launch.
    static func seedIfNeeded(context: ModelContext) {
        seedRubsIfNeeded(context: context)
        seedCooksIfNeeded(context: context)
    }

    // MARK: Rubs

    static func seedRubsIfNeeded(context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Rub>())) ?? 0
        guard existing == 0 else { return }
        for b in BuiltInRubs.all {
            let rub = Rub(name: b.name,
                          ingredients: b.ingredients,
                          steps: b.steps,
                          notes: b.notes,
                          isBuiltInCopy: false)
            context.insert(rub)
        }
        try? context.save()
    }

    // MARK: Cooks (a log + one planned + one live demo)

    static func seedCooksIfNeeded(context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Cook>())) ?? 0
        guard existing == 0 else { return }
        insertSampleCooks(context: context)
    }

    /// Force-insert the sample cooks (used by "Load sample data" when the log is empty).
    static func insertSampleCooks(context: ModelContext) {
        let now = Date()

        struct Plan {
            let name: String
            let protein: Protein
            let cut: String
            let weightKg: Double
            let method: CookMethod
            let wood: String
            let rub: String
            let rating: Int
            let daysAgo: Int
            let notes: String
        }

        let plans: [Plan] = [
            Plan(name: "Weekend Brisket", protein: .beef, cut: "Brisket (whole packer)", weightKg: 6.0, method: .smoke, wood: "Post Oak", rub: "Classic SPG", rating: 5, daysAgo: 4, notes: "Wrapped at the stall, probed like butter at 95°C."),
            Plan(name: "Sunday Ribs", protein: .pork, cut: "Pork Ribs (spare / St. Louis)", weightKg: 1.6, method: .smoke, wood: "Cherry", rub: "Memphis Dust", rating: 4, daysAgo: 7, notes: "Great bend test, a touch sweet."),
            Plan(name: "Pulled Pork", protein: .pork, cut: "Pork Shoulder (Boston butt)", weightKg: 3.8, method: .smoke, wood: "Apple", rub: "Carolina Pork Rub", rating: 5, daysAgo: 11, notes: "16 hours, fell apart."),
            Plan(name: "Spatchcock Chicken", protein: .poultry, cut: "Whole Chicken", weightKg: 1.8, method: .grill, wood: "Apple", rub: "Poultry Seasoning", rating: 4, daysAgo: 14, notes: "Crispy skin from the baking powder."),
            Plan(name: "Reverse-Sear Ribeyes", protein: .beef, cut: "Ribeye Steak", weightKg: 0.9, method: .reverseSear, wood: "Oak", rub: "Classic SPG", rating: 5, daysAgo: 18, notes: "Edge to edge medium-rare."),
            Plan(name: "Smoked Wings", protein: .poultry, cut: "Chicken Wings", weightKg: 1.4, method: .smoke, wood: "Hickory", rub: "Poultry Seasoning", rating: 4, daysAgo: 21, notes: "Finished hot for crunch."),
            Plan(name: "Tri-Tip Dinner", protein: .beef, cut: "Tri-Tip", weightKg: 1.3, method: .reverseSear, wood: "Oak", rub: "Coffee Chili Rub", rating: 5, daysAgo: 25, notes: "Santa Maria style, sliced thin."),
            Plan(name: "Cedar Salmon", protein: .fish, cut: "Salmon Fillet", weightKg: 0.7, method: .smoke, wood: "Alder", rub: "Lemon Herb (Fish & Veg)", rating: 4, daysAgo: 28, notes: "Pulled at 54°C, silky."),
            Plan(name: "Lamb Chops", protein: .lamb, cut: "Lamb Chops", weightKg: 0.8, method: .grill, wood: "Oak", rub: "Coffee Chili Rub", rating: 4, daysAgo: 33, notes: "Quick sear, medium-rare."),
            Plan(name: "Pork Tenderloin", protein: .pork, cut: "Pork Tenderloin", weightKg: 0.6, method: .grill, wood: "Apple", rub: "Carolina Pork Rub", rating: 3, daysAgo: 37, notes: "A little past, still juicy."),
            Plan(name: "Beef Short Ribs", protein: .beef, cut: "Beef Short Ribs", weightKg: 2.2, method: .smoke, wood: "Mesquite", rub: "Classic SPG", rating: 5, daysAgo: 42, notes: "Dino ribs — showstopper."),
            Plan(name: "Smoked Corn", protein: .veg, cut: "Corn on the Cob", weightKg: 0.9, method: .smoke, wood: "Cherry", rub: "Lemon Herb (Fish & Veg)", rating: 4, daysAgo: 46, notes: "Sweet with a little smoke.")
        ]

        for plan in plans {
            let guide = DonenessGuide.entry(protein: plan.protein, cut: plan.cut)
            let target = guide?.defaultTargetC ?? 71
            let ambient = guide?.smokerTempC ?? 121
            let total = CookEngine.estimatedTotalMinutes(weightKg: plan.weightKg, method: plan.method, guide: guide)
            let start = now.addingTimeInterval(Double(-plan.daysAgo) * 86_400)
            let finish = start.addingTimeInterval(total * 60)
            let restMins = guide?.restMinutes ?? 10

            let cook = Cook(name: plan.name,
                            protein: plan.protein,
                            cut: plan.cut,
                            weightKg: plan.weightKg,
                            method: plan.method,
                            targetInternalTempC: target,
                            ambientTempC: ambient,
                            woodType: plan.wood,
                            rubName: plan.rub,
                            status: .done,
                            startDate: start,
                            restStartDate: finish,
                            finishedDate: finish.addingTimeInterval(Double(restMins) * 60),
                            resultRating: plan.rating,
                            notes: plan.notes,
                            createdAt: start)
            context.insert(cook)
            attachTempCurve(to: cook, start: start, totalMinutes: total, target: target)
        }

        // One planned cook so the Cooks list shows the full lifecycle.
        if let guide = DonenessGuide.entry(protein: .pork, cut: "Baby Back Ribs") {
            let planned = Cook(name: "Next Sunday Ribs",
                               protein: .pork,
                               cut: "Baby Back Ribs",
                               weightKg: 1.4,
                               method: .smoke,
                               targetInternalTempC: guide.defaultTargetC,
                               ambientTempC: guide.smokerTempC,
                               woodType: "Cherry",
                               rubName: "Memphis Dust",
                               status: .planned,
                               notes: "Picked up a rack for the weekend.",
                               createdAt: now)
            context.insert(planned)
        }

        try? context.save()
    }

    /// Build a believable rising internal-temp curve for a finished cook.
    private static func attachTempCurve(to cook: Cook, start: Date, totalMinutes: Double, target: Double) {
        let points = 6
        guard points > 1 else { return }
        for i in 0..<points {
            let frac = Double(i) / Double(points - 1)
            let t = start.addingTimeInterval(totalMinutes * 60 * frac)
            // Ease toward target; last reading sits at/just over target.
            let temp = 8 + (target - 8) * pow(frac, 0.8)
            let log = TempLog(time: t, internalTempC: min(temp, target + 1), note: i == 0 ? "On the pit" : "")
            log.cook = cook
            cook.tempLogs.append(log)
        }
    }

    // MARK: Clear (used by Settings)

    static func clearAllCooks(context: ModelContext) {
        if let all = try? context.fetch(FetchDescriptor<Cook>()) {
            for c in all { context.delete(c) }
            try? context.save()
        }
    }
}
