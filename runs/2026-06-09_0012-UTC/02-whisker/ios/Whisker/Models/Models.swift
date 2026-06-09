import Foundation
import SwiftData

/// A pet. Owns its care tasks, weight entries, and health events.
@Model
final class Pet {
    var name: String
    var speciesRaw: String
    var breed: String
    var birthday: Date?
    var colorRaw: String
    var notes: String
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CareTask.pet)
    var tasks: [CareTask] = []
    @Relationship(deleteRule: .cascade, inverse: \WeightEntry.pet)
    var weights: [WeightEntry] = []
    @Relationship(deleteRule: .cascade, inverse: \HealthEvent.pet)
    var events: [HealthEvent] = []

    init(name: String,
         species: Species,
         breed: String = "",
         birthday: Date? = nil,
         color: PetColor = .teal,
         notes: String = "") {
        self.name = name
        self.speciesRaw = species.rawValue
        self.breed = breed
        self.birthday = birthday
        self.colorRaw = color.rawValue
        self.notes = notes
        self.isArchived = false
        self.createdAt = .now
    }

    var species: Species {
        get { Species(rawValue: speciesRaw) ?? .other }
        set { speciesRaw = newValue.rawValue }
    }
    var color: PetColor {
        get { PetColor(rawValue: colorRaw) ?? .teal }
        set { colorRaw = newValue.rawValue }
    }

    var activeTasks: [CareTask] { tasks.filter { $0.isActive } }

    /// Latest weight in kilograms, if recorded.
    var latestWeightKg: Double? {
        weights.sorted { $0.date > $1.date }.first?.kilograms
    }
}

/// A recurring care responsibility for a pet.
@Model
final class CareTask {
    var title: String
    var kindRaw: String
    var intervalDays: Int
    var lastDone: Date?
    var isActive: Bool
    var createdAt: Date
    var pet: Pet?

    init(title: String, kind: CareKind, intervalDays: Int, lastDone: Date? = nil) {
        self.title = title
        self.kindRaw = kind.rawValue
        self.intervalDays = max(1, intervalDays)
        self.lastDone = lastDone
        self.isActive = true
        self.createdAt = .now
    }

    var kind: CareKind {
        get { CareKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    /// Next due date. If never done, due today.
    var nextDue: Date {
        guard let last = lastDone else { return Calendar.current.startOfDay(for: .now) }
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: last) ?? last
    }
}

/// A weight measurement, stored canonically in kilograms.
@Model
final class WeightEntry {
    var date: Date
    var kilograms: Double
    var note: String
    var pet: Pet?

    init(date: Date = .now, kilograms: Double, note: String = "") {
        self.date = date
        self.kilograms = max(0, kilograms)
        self.note = note
    }
}

/// A point-in-time health record.
@Model
final class HealthEvent {
    var date: Date
    var kindRaw: String
    var title: String
    var detail: String
    var pet: Pet?

    init(date: Date = .now, kind: EventKind, title: String, detail: String = "") {
        self.date = date
        self.kindRaw = kind.rawValue
        self.title = title
        self.detail = detail
    }

    var kind: EventKind {
        get { EventKind(rawValue: kindRaw) ?? .note }
        set { kindRaw = newValue.rawValue }
    }
}
