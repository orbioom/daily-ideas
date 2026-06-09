import Foundation
import SwiftData

/// Seeds the built-in trigger / symptom / medication catalogs plus a few months
/// of sample attacks on first launch, so charts and rankings are never empty for
/// a brand-new user. Guarded so it runs at most once.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Trigger>())) ?? []
        guard existing.isEmpty else { return }

        // MARK: Built-in triggers
        let triggerSpec: [(String, TriggerCategory)] = [
            ("Stress", .lifestyle),
            ("Poor sleep", .lifestyle),
            ("Dehydration", .lifestyle),
            ("Skipped meal", .lifestyle),
            ("Screen time", .lifestyle),
            ("Alcohol", .food),
            ("Caffeine", .food),
            ("Chocolate", .food),
            ("Aged cheese", .food),
            ("Bright light", .environment),
            ("Loud noise", .environment),
            ("Weather change", .environment),
            ("Strong smell", .environment),
            ("Hormonal", .hormonal)
        ]
        var triggers: [Trigger] = triggerSpec.map { Trigger(name: $0.0, category: $0.1, isBuiltIn: true) }
        triggers.forEach { context.insert($0) }

        // MARK: Built-in symptoms
        let symptomNames = [
            "Nausea", "Light sensitivity", "Sound sensitivity", "Visual aura",
            "Dizziness", "Neck pain", "Vomiting", "Fatigue", "Tingling"
        ]
        var symptoms: [Symptom] = symptomNames.map { Symptom(name: $0, isBuiltIn: true) }
        symptoms.forEach { context.insert($0) }

        // MARK: Built-in medication catalog
        let medSpec: [(String, MedType, Double)] = [
            ("Ibuprofen", .acute, 400),
            ("Sumatriptan", .acute, 50),
            ("Rizatriptan", .acute, 10),
            ("Acetaminophen", .acute, 500),
            ("Naproxen", .acute, 500),
            ("Propranolol", .preventive, 40),
            ("Topiramate", .preventive, 25)
        ]
        let meds: [Medication] = medSpec.map { Medication(name: $0.0, type: $0.1, defaultDoseMg: $0.2, isBuiltIn: true) }
        meds.forEach { context.insert($0) }

        // MARK: Sample attacks over the past ~5 months
        seedAttacks(context, triggers: triggers, symptoms: symptoms, acuteMeds: meds.filter { $0.type == .acute })

        try? context.save()
    }

    private static func seedAttacks(_ context: ModelContext,
                                    triggers: [Trigger],
                                    symptoms: [Symptom],
                                    acuteMeds: [Medication]) {
        let cal = Calendar.current
        var rng = SystemRandomNumberGenerator()

        // Weight some triggers heavier so correlation ranking is meaningful.
        // Index into `triggers`: Stress(0), Poor sleep(1), Dehydration(2), Screen time(4), Weather(11) common.
        let weightedTriggerIndices: [Int] = [0,0,0,0, 1,1,1, 2,2, 4,4, 11,11, 5, 6, 9, 13]
        let types: [HeadacheType] = [.migraine, .migraine, .migraine, .tension, .tension, .cluster, .sinus]
        let locations: [HeadLocation] = HeadLocation.allCases
        let reliefs: [Relief] = [.none, .some, .some, .lots, .lots, .complete]

        for i in 0..<50 {
            // Spread starts across the last ~150 days.
            let daysAgo = Int.random(in: 0...150, using: &rng)
            guard let dayBase = cal.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            let hour = Int.random(in: 6...22, using: &rng)
            let minute = [0, 15, 30, 45].randomElement(using: &rng) ?? 0
            guard let start = cal.date(bySettingHour: hour, minute: minute, second: 0, of: dayBase) else { continue }

            let intensity = Int.random(in: 3...9, using: &rng)
            // Durations 1–48h, weighted toward 2–12h.
            let durationMinutes: Int = {
                let roll = Int.random(in: 0...100, using: &rng)
                if roll < 70 { return Int.random(in: 120...720, using: &rng) }   // 2–12h
                if roll < 90 { return Int.random(in: 60...180, using: &rng) }    // 1–3h
                return Int.random(in: 720...2880, using: &rng)                   // 12–48h
            }()
            let end = cal.date(byAdding: .minute, value: durationMinutes, to: start)

            let attack = Attack(
                start: start,
                end: end,
                intensity: intensity,
                type: types.randomElement(using: &rng) ?? .migraine,
                location: locations.randomElement(using: &rng) ?? .unspecified,
                auraPresent: Bool.random(using: &rng) && intensity >= 6,
                note: i % 9 == 0 ? "Came on after a long workday." : ""
            )

            // 1–4 triggers (weighted), de-duplicated.
            let triggerCount = Int.random(in: 1...4, using: &rng)
            var chosenTriggers = Set<Int>()
            for _ in 0..<triggerCount {
                if let idx = weightedTriggerIndices.randomElement(using: &rng) { chosenTriggers.insert(idx) }
            }
            attack.triggers = chosenTriggers.compactMap { triggers.indices.contains($0) ? triggers[$0] : nil }

            // 1–4 symptoms.
            let symptomCount = Int.random(in: 1...4, using: &rng)
            var chosenSymptoms = Set<Int>()
            for _ in 0..<symptomCount {
                chosenSymptoms.insert(Int.random(in: 0..<symptoms.count, using: &rng))
            }
            attack.symptoms = chosenSymptoms.map { symptoms[$0] }

            context.insert(attack)

            // ~70% have a med taken.
            if Int.random(in: 0...100, using: &rng) < 70, let med = acuteMeds.randomElement(using: &rng) {
                let taken = MedTaken(
                    name: med.name,
                    doseMg: med.defaultDoseMg,
                    minutesAfterOnset: Int.random(in: 5...120, using: &rng),
                    relief: reliefs.randomElement(using: &rng) ?? .some,
                    isAcute: true
                )
                taken.attack = attack
                context.insert(taken)
            }
        }
    }
}
