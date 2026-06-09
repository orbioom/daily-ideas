import Foundation
import SwiftData

/// Optional sample data so the charts and lists can be explored immediately.
enum SeedData {

    static func loadSample(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        // Dog with a full weight history (exercises the chart at volume).
        let luna = Pet(name: "Luna", species: .dog, breed: "Border Collie",
                       birthday: cal.date(byAdding: .year, value: -3, to: now),
                       color: .amber, notes: "Loves the morning loop by the river.")
        context.insert(luna)
        addWeights(to: luna, base: 18.5, amplitude: 0.6, count: 52, context: context)
        addTasks(to: luna, kinds: [(.feeding, 1), (.exercise, 1), (.fleaTick, 30), (.nailTrim, 21), (.vet, 365)], context: context)
        addEvents(to: luna, context: context)

        let milo = Pet(name: "Milo", species: .cat, breed: "Tabby",
                       birthday: cal.date(byAdding: .month, value: -20, to: now),
                       color: .slate, notes: "Indoor. Very particular about the litter.")
        context.insert(milo)
        addWeights(to: milo, base: 4.6, amplitude: 0.2, count: 40, context: context)
        addTasks(to: milo, kinds: [(.feeding, 1), (.litter, 3), (.grooming, 30), (.deworming, 90)], context: context)

        try? context.save()
    }

    private static func addWeights(to pet: Pet, base: Double, amplitude: Double, count: Int, context: ModelContext) {
        let cal = Calendar.current
        for i in 0..<count {
            guard let date = cal.date(byAdding: .day, value: -i * 7, to: .now) else { continue }
            let drift = Double(count - i) * 0.01
            let wobble = amplitude * sin(Double(i) / 3.0)
            let entry = WeightEntry(date: date, kilograms: max(0.1, base + drift + wobble))
            entry.pet = pet
            context.insert(entry)
        }
    }

    private static func addTasks(to pet: Pet, kinds: [(CareKind, Int)], context: ModelContext) {
        let cal = Calendar.current
        for (kind, interval) in kinds {
            let last = cal.date(byAdding: .day, value: -(interval - 1), to: .now)
            let task = CareTask(title: kind.title, kind: kind, intervalDays: interval, lastDone: last)
            task.pet = pet
            context.insert(task)
        }
    }

    private static func addEvents(to pet: Pet, context: ModelContext) {
        let cal = Calendar.current
        let samples: [(Int, EventKind, String, String)] = [
            (-200, .vaccine, "Rabies booster", "Due again next year."),
            (-120, .vetVisit, "Annual check-up", "Clean bill of health."),
            (-45, .symptom, "Limping (left paw)", "Resolved after two days of rest.")
        ]
        for (offset, kind, title, detail) in samples {
            let e = HealthEvent(date: cal.date(byAdding: .day, value: offset, to: .now) ?? .now,
                                kind: kind, title: title, detail: detail)
            e.pet = pet
            context.insert(e)
        }
    }
}
