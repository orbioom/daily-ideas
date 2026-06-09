import SwiftUI

/// The kind of animal a pet is. Drives icon, default weight range, and copy.
enum Species: String, CaseIterable, Identifiable, Codable {
    case dog, cat, rabbit, bird, reptile, smallPet, fish, horse, other
    var id: String { rawValue }

    var title: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        case .rabbit: return "Rabbit"
        case .bird: return "Bird"
        case .reptile: return "Reptile"
        case .smallPet: return "Small pet"
        case .fish: return "Fish"
        case .horse: return "Horse"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .rabbit: return "hare.fill"
        case .bird: return "bird.fill"
        case .reptile: return "lizard.fill"
        case .smallPet: return "pawprint.fill"
        case .fish: return "fish.fill"
        case .horse: return "tortoise.fill"
        case .other: return "pawprint.fill"
        }
    }
}

/// A recurring care responsibility. Each has a sensible default cadence.
enum CareKind: String, CaseIterable, Identifiable, Codable {
    case feeding, medication, fleaTick, deworming, grooming, nailTrim, vet, vaccine, litter, exercise, other
    var id: String { rawValue }

    var title: String {
        switch self {
        case .feeding: return "Feeding"
        case .medication: return "Medication"
        case .fleaTick: return "Flea & tick"
        case .deworming: return "Deworming"
        case .grooming: return "Grooming"
        case .nailTrim: return "Nail trim"
        case .vet: return "Vet check-up"
        case .vaccine: return "Vaccination"
        case .litter: return "Litter change"
        case .exercise: return "Exercise / walk"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .feeding: return "fork.knife"
        case .medication: return "pills.fill"
        case .fleaTick: return "ant.fill"
        case .deworming: return "cross.vial.fill"
        case .grooming: return "comb.fill"
        case .nailTrim: return "scissors"
        case .vet: return "stethoscope"
        case .vaccine: return "syringe.fill"
        case .litter: return "trash.fill"
        case .exercise: return "figure.walk"
        case .other: return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .feeding: return Color(hex: 0xC08A4E)
        case .medication: return Color(hex: 0xC0553E)
        case .fleaTick: return Color(hex: 0x9E7B3E)
        case .deworming: return Color(hex: 0x6E8F3E)
        case .grooming: return Color(hex: 0x4E8FA8)
        case .nailTrim: return Color(hex: 0x8B7BB0)
        case .vet: return Color(hex: 0x4F8FB9)
        case .vaccine: return Color(hex: 0xC04E7A)
        case .litter: return Color(hex: 0x6E7287)
        case .exercise: return Color(hex: 0x3E9E78)
        case .other: return Color(hex: 0x7B8FA0)
        }
    }

    /// Default repeat interval in days.
    var defaultInterval: Int {
        switch self {
        case .feeding: return 1
        case .medication: return 1
        case .fleaTick: return 30
        case .deworming: return 90
        case .grooming: return 30
        case .nailTrim: return 21
        case .vet: return 365
        case .vaccine: return 365
        case .litter: return 3
        case .exercise: return 1
        case .other: return 7
        }
    }
}

/// A point-in-time health record (not recurring).
enum EventKind: String, CaseIterable, Identifiable, Codable {
    case vetVisit, vaccine, medication, symptom, weight, grooming, milestone, note
    var id: String { rawValue }

    var title: String {
        switch self {
        case .vetVisit: return "Vet visit"
        case .vaccine: return "Vaccination"
        case .medication: return "Medication"
        case .symptom: return "Symptom"
        case .weight: return "Weight"
        case .grooming: return "Grooming"
        case .milestone: return "Milestone"
        case .note: return "Note"
        }
    }

    var icon: String {
        switch self {
        case .vetVisit: return "stethoscope"
        case .vaccine: return "syringe.fill"
        case .medication: return "pills.fill"
        case .symptom: return "thermometer.medium"
        case .weight: return "scalemass.fill"
        case .grooming: return "comb.fill"
        case .milestone: return "star.fill"
        case .note: return "note.text"
        }
    }

    var tint: Color {
        switch self {
        case .vetVisit: return Color(hex: 0x4F8FB9)
        case .vaccine: return Color(hex: 0xC04E7A)
        case .medication: return Color(hex: 0xC0553E)
        case .symptom: return Color(hex: 0xC08A3E)
        case .weight: return Color(hex: 0x3E9E88)
        case .grooming: return Color(hex: 0x4E8FA8)
        case .milestone: return Color(hex: 0xC07A4E)
        case .note: return Color(hex: 0x7B8FA0)
        }
    }
}

/// Avatar accent colors a pet can be given.
enum PetColor: String, CaseIterable, Identifiable, Codable {
    case amber, rust, sage, teal, indigo, plum, rose, slate
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .amber: return Color(hex: 0xC08A4E)
        case .rust: return Color(hex: 0xC0553E)
        case .sage: return Color(hex: 0x6E8F5E)
        case .teal: return Color(hex: 0x4FA8A0)
        case .indigo: return Color(hex: 0x5A6BB0)
        case .plum: return Color(hex: 0x8B6FB0)
        case .rose: return Color(hex: 0xC06A8C)
        case .slate: return Color(hex: 0x6E7287)
        }
    }
}
