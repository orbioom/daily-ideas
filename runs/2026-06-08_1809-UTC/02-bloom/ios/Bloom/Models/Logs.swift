import Foundation
import SwiftData

/// A logged symptom on a given day with a 1–3 severity.
@Model
final class SymptomEntry {
    var date: Date
    var symptomRaw: String
    var severity: Int      // 1 mild, 2 moderate, 3 strong
    var note: String

    init(date: Date = .now, symptom: Symptom = .nausea, severity: Int = 1, note: String = "") {
        self.date = date
        self.symptomRaw = symptom.rawValue
        self.severity = min(max(severity, 1), 3)
        self.note = note
    }

    var symptom: Symptom {
        get { Symptom(rawValue: symptomRaw) ?? .other }
        set { symptomRaw = newValue.rawValue }
    }
}

enum Symptom: String, CaseIterable, Identifiable, Codable {
    case nausea, fatigue, cravings, heartburn, backPain, swelling
    case headache, cramps, moodSwings, insomnia, kicks, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nausea:     return "Nausea"
        case .fatigue:    return "Fatigue"
        case .cravings:   return "Cravings"
        case .heartburn:  return "Heartburn"
        case .backPain:   return "Back pain"
        case .swelling:   return "Swelling"
        case .headache:   return "Headache"
        case .cramps:     return "Cramps"
        case .moodSwings: return "Mood swings"
        case .insomnia:   return "Insomnia"
        case .kicks:      return "Baby kicks"
        case .other:      return "Other"
        }
    }

    var icon: String {
        switch self {
        case .nausea:     return "wind"
        case .fatigue:    return "zzz"
        case .cravings:   return "fork.knife"
        case .heartburn:  return "flame"
        case .backPain:   return "figure.walk"
        case .swelling:   return "drop"
        case .headache:   return "brain.head.profile"
        case .cramps:     return "bolt"
        case .moodSwings: return "cloud.sun"
        case .insomnia:   return "moon.stars"
        case .kicks:      return "figure.child"
        case .other:      return "ellipsis.circle"
        }
    }
}

/// A weight measurement in kilograms (canonical unit).
@Model
final class WeightEntry {
    var date: Date
    var kg: Double

    init(date: Date = .now, kg: Double) {
        self.date = date
        self.kg = kg
    }
}

/// A prenatal appointment.
@Model
final class Appointment {
    var date: Date
    var title: String
    var location: String
    var notes: String
    var isDone: Bool

    init(date: Date, title: String, location: String = "", notes: String = "", isDone: Bool = false) {
        self.date = date
        self.title = title
        self.location = location
        self.notes = notes
        self.isDone = isDone
    }
}

/// A "count the kicks" session — usually counting to 10 movements.
@Model
final class KickSession {
    var start: Date
    var end: Date
    var count: Int

    init(start: Date, end: Date, count: Int) {
        self.start = start
        self.end = end
        self.count = count
    }

    var durationSeconds: Int { max(0, Int(end.timeIntervalSince(start))) }
}

/// A single timed contraction used for frequency/duration analysis.
@Model
final class Contraction {
    var start: Date
    var durationSeconds: Int

    init(start: Date, durationSeconds: Int) {
        self.start = start
        self.durationSeconds = max(0, durationSeconds)
    }
}
