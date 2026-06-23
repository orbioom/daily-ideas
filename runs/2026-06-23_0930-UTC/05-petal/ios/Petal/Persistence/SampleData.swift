import Foundation
import SwiftData

/// Seeds realistic sample pets and records. Generates well over 50 records in
/// total (pets + medications + vaccinations + visits + weights + feedings).
enum SampleData {
    private static func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now
    }
    private static func month(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: offset, to: .now) ?? .now
    }
    private static func atTime(_ hour: Int, _ minute: Int) -> Int { hour * 60 + minute }

    /// Inserts sample data into the given context if no pets exist yet.
    static func seed(into context: ModelContext) {
        // Avoid double-seeding.
        let existing = (try? context.fetch(FetchDescriptor<Pet>())) ?? []
        guard existing.isEmpty else { return }

        // MARK: Luna — a 4yr Border Collie
        let luna = Pet(name: "Luna", species: .dog, breed: "Border Collie",
                       birthday: month(-50), avatarSymbol: "dog.fill", avatarTint: .teal,
                       notes: "High energy. Loves frisbee. Slightly sensitive stomach.")
        context.insert(luna)
        luna.medications = [
            Medication(name: "Apoquel", dosage: "16 mg", frequency: .daily, nextDue: day(0),
                       notes: "For seasonal allergies."),
            Medication(name: "Heartgard Plus", dosage: "1 chew", frequency: .monthly, nextDue: day(3),
                       notes: "Heartworm prevention."),
            Medication(name: "NexGard", dosage: "1 chew", frequency: .monthly, nextDue: day(-1),
                       notes: "Flea & tick."),
        ]
        luna.vaccinations = [
            Vaccination(name: "Rabies", dateAdministered: month(-11), nextDue: month(13), clinic: "Maple Vet", lotNumber: "RB-4421"),
            Vaccination(name: "DHPP", dateAdministered: month(-2), nextDue: month(10), clinic: "Maple Vet", lotNumber: "DH-9087"),
            Vaccination(name: "Bordetella", dateAdministered: month(-7), nextDue: day(12), clinic: "Maple Vet"),
            Vaccination(name: "Leptospirosis", dateAdministered: month(-2), nextDue: month(10), clinic: "Maple Vet"),
        ]
        luna.vetVisits = [
            VetVisit(date: month(-2), reason: .checkup, clinic: "Maple Vet", vetName: "Dr. Reyes",
                     diagnosis: "Healthy. Mild tartar.", notes: "Recommend dental in 6 months.", cost: 95, followUpDate: day(5)),
            VetVisit(date: month(-7), reason: .illness, clinic: "Maple Vet", vetName: "Dr. Reyes",
                     diagnosis: "Gastroenteritis", notes: "Bland diet 5 days.", cost: 140),
        ]
        luna.feedings = [
            FeedingSchedule(label: "Breakfast", food: "Salmon kibble", portion: "1 cup", timeMinutes: atTime(7, 30)),
            FeedingSchedule(label: "Dinner", food: "Salmon kibble", portion: "1 cup", timeMinutes: atTime(18, 0)),
        ]
        addWeightSeries(to: luna, base: 18.5, drift: 0.4, points: 10, context: context)

        // MARK: Milo — a 2yr Tabby cat
        let milo = Pet(name: "Milo", species: .cat, breed: "Domestic Shorthair",
                       birthday: month(-26), avatarSymbol: "cat.fill", avatarTint: .amber,
                       notes: "Indoor cat. Microchipped.")
        context.insert(milo)
        milo.medications = [
            Medication(name: "Revolution Plus", dosage: "1 applicator", frequency: .monthly, nextDue: day(2),
                       notes: "Flea, tick & heartworm."),
            Medication(name: "Gabapentin", dosage: "50 mg", frequency: .twiceDaily, nextDue: day(0),
                       courseEnd: day(4), notes: "Post-dental, taper as directed."),
        ]
        milo.vaccinations = [
            Vaccination(name: "FVRCP", dateAdministered: month(-4), nextDue: month(8), clinic: "City Cats Clinic"),
            Vaccination(name: "Rabies", dateAdministered: month(-4), nextDue: day(20), clinic: "City Cats Clinic", lotNumber: "RB-1199"),
            Vaccination(name: "FeLV", dateAdministered: month(-13), nextDue: day(-3), clinic: "City Cats Clinic"),
        ]
        milo.vetVisits = [
            VetVisit(date: day(-10), reason: .dental, clinic: "City Cats Clinic", vetName: "Dr. Okafor",
                     diagnosis: "Dental cleaning, 1 extraction", notes: "Soft food 1 week.", cost: 420, followUpDate: day(4)),
        ]
        milo.feedings = [
            FeedingSchedule(label: "Morning", food: "Wet food", portion: "1/2 can", timeMinutes: atTime(8, 0)),
            FeedingSchedule(label: "Evening", food: "Wet food", portion: "1/2 can", timeMinutes: atTime(19, 30)),
        ]
        addWeightSeries(to: milo, base: 4.6, drift: 0.15, points: 9, context: context)

        // MARK: Clover — a 1yr Holland Lop rabbit
        let clover = Pet(name: "Clover", species: .rabbit, breed: "Holland Lop",
                         birthday: month(-13), avatarSymbol: "hare.fill", avatarTint: .pink,
                         notes: "Litter trained. Unlimited timothy hay.")
        context.insert(clover)
        clover.medications = [
            Medication(name: "Critical Care", dosage: "as needed", frequency: .asNeeded, nextDue: day(1),
                       notes: "Only if not eating."),
        ]
        clover.vaccinations = [
            Vaccination(name: "RHDV2", dateAdministered: month(-6), nextDue: day(8), clinic: "Exotic Pet Center"),
        ]
        clover.vetVisits = [
            VetVisit(date: month(-1), reason: .checkup, clinic: "Exotic Pet Center", vetName: "Dr. Lin",
                     diagnosis: "Healthy. Teeth aligned.", cost: 75),
        ]
        clover.feedings = [
            FeedingSchedule(label: "Pellets AM", food: "Timothy pellets", portion: "1/4 cup", timeMinutes: atTime(7, 0)),
            FeedingSchedule(label: "Greens PM", food: "Leafy greens", portion: "1 handful", timeMinutes: atTime(17, 0)),
        ]
        addWeightSeries(to: clover, base: 1.7, drift: 0.05, points: 8, context: context)

        // MARK: Kiwi — a 3yr Budgerigar
        let kiwi = Pet(name: "Kiwi", species: .bird, breed: "Budgerigar",
                       birthday: month(-38), avatarSymbol: "bird.fill", avatarTint: .blue,
                       notes: "Loves millet. Wings clipped.")
        context.insert(kiwi)
        kiwi.vaccinations = [
            Vaccination(name: "Polyomavirus", dateAdministered: month(-10), nextDue: month(2), clinic: "Avian Care"),
        ]
        kiwi.vetVisits = [
            VetVisit(date: month(-3), reason: .checkup, clinic: "Avian Care", vetName: "Dr. Patel",
                     diagnosis: "Healthy plumage", cost: 60),
        ]
        kiwi.feedings = [
            FeedingSchedule(label: "Seed mix", food: "Budgie seed", portion: "2 tsp", timeMinutes: atTime(8, 30)),
        ]
        addWeightSeries(to: kiwi, base: 0.035, drift: 0.003, points: 7, context: context)

        // MARK: Bandit — a 6yr Beagle
        let bandit = Pet(name: "Bandit", species: .dog, breed: "Beagle",
                         birthday: month(-74), avatarSymbol: "dog.fill", avatarTint: .lilac,
                         notes: "Food-motivated. Watch weight.")
        context.insert(bandit)
        bandit.medications = [
            Medication(name: "Galliprant", dosage: "60 mg", frequency: .daily, nextDue: day(0),
                       notes: "Joint comfort."),
            Medication(name: "Simparica Trio", dosage: "1 chew", frequency: .monthly, nextDue: day(6)),
        ]
        bandit.vaccinations = [
            Vaccination(name: "Rabies", dateAdministered: month(-20), nextDue: day(-5), clinic: "Maple Vet", lotNumber: "RB-7781"),
            Vaccination(name: "DHPP", dateAdministered: month(-8), nextDue: month(4), clinic: "Maple Vet"),
        ]
        bandit.vetVisits = [
            VetVisit(date: month(-1), reason: .checkup, clinic: "Maple Vet", vetName: "Dr. Reyes",
                     diagnosis: "Overweight. Start joint diet.", notes: "Recheck weight in 4 weeks.", cost: 110, followUpDate: day(9)),
            VetVisit(date: month(-9), reason: .injury, clinic: "Emergency Pet ER", vetName: "Dr. Shah",
                     diagnosis: "Paw laceration", notes: "Sutures removed after 10 days.", cost: 300),
        ]
        bandit.feedings = [
            FeedingSchedule(label: "Breakfast", food: "Weight-control kibble", portion: "3/4 cup", timeMinutes: atTime(7, 15)),
            FeedingSchedule(label: "Dinner", food: "Weight-control kibble", portion: "3/4 cup", timeMinutes: atTime(18, 30)),
        ]
        addWeightSeries(to: bandit, base: 14.2, drift: 0.5, points: 11, context: context)
    }

    /// Adds a descending-date weight series with gentle realistic drift.
    private static func addWeightSeries(to pet: Pet, base: Double, drift: Double, points: Int, context: ModelContext) {
        var entries: [WeightEntry] = []
        for i in 0..<points {
            let weeksAgo = (points - 1 - i) * 3
            let date = Calendar.current.date(byAdding: .day, value: -weeksAgo * 7 / 3, to: .now) ?? .now
            // Deterministic pseudo-random wobble so charts look natural but stable.
            let wobble = (Double((i * 37) % 11) / 10.0 - 0.5) * drift
            let trend = Double(i) / Double(max(1, points - 1)) * drift
            let kg = max(0.01, base - drift + trend + wobble)
            entries.append(WeightEntry(date: date, kilograms: kg))
        }
        pet.weightEntries = entries
    }
}
