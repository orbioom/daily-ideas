import Foundation
import SwiftData
import SwiftUI

/// A pet profile. Owns all related care, health, weight and feeding records via
/// cascading relationships so deleting a pet cleans up everything cleanly.
@Model
final class Pet {
    var id: UUID
    var name: String
    /// Stored as the raw value of `Species` for forward compatibility.
    var speciesRaw: String
    var breed: String
    var birthday: Date?
    /// SF Symbol name used as the avatar emblem.
    var avatarSymbol: String
    /// Hex-free token name of the avatar tint (one of Theme accent tokens).
    var avatarTintRaw: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Medication.pet)
    var medications: [Medication] = []

    @Relationship(deleteRule: .cascade, inverse: \Vaccination.pet)
    var vaccinations: [Vaccination] = []

    @Relationship(deleteRule: .cascade, inverse: \VetVisit.pet)
    var vetVisits: [VetVisit] = []

    @Relationship(deleteRule: .cascade, inverse: \WeightEntry.pet)
    var weightEntries: [WeightEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \FeedingSchedule.pet)
    var feedings: [FeedingSchedule] = []

    init(
        id: UUID = UUID(),
        name: String,
        species: Species,
        breed: String = "",
        birthday: Date? = nil,
        avatarSymbol: String? = nil,
        avatarTint: AvatarTint = .teal,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.speciesRaw = species.rawValue
        self.breed = breed
        self.birthday = birthday
        self.avatarSymbol = avatarSymbol ?? species.defaultSymbol
        self.avatarTintRaw = avatarTint.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }

    var species: Species {
        get { Species(rawValue: speciesRaw) ?? .other }
        set { speciesRaw = newValue.rawValue }
    }

    var avatarTint: AvatarTint {
        get { AvatarTint(rawValue: avatarTintRaw) ?? .teal }
        set { avatarTintRaw = newValue.rawValue }
    }

    /// Human-readable age, e.g. "3 yr 2 mo" or "5 mo". Returns nil if no birthday.
    var ageText: String? {
        guard let birthday else { return nil }
        let comps = Calendar.current.dateComponents([.year, .month], from: birthday, to: .now)
        let years = max(0, comps.year ?? 0)
        let months = max(0, comps.month ?? 0)
        if years <= 0 && months <= 0 { return "Newborn" }
        if years <= 0 { return "\(months) mo" }
        if months <= 0 { return "\(years) yr" }
        return "\(years) yr \(months) mo"
    }

    /// Latest recorded weight, if any.
    var latestWeight: WeightEntry? {
        weightEntries.sorted { $0.date > $1.date }.first
    }
}

enum Species: String, CaseIterable, Identifiable, Codable {
    case dog, cat, rabbit, bird, reptile, fish, horse, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        case .rabbit: return "Rabbit"
        case .bird: return "Bird"
        case .reptile: return "Reptile"
        case .fish: return "Fish"
        case .horse: return "Horse"
        case .other: return "Other"
        }
    }

    var defaultSymbol: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .rabbit: return "hare.fill"
        case .bird: return "bird.fill"
        case .reptile: return "lizard.fill"
        case .fish: return "fish.fill"
        case .horse: return "tortoise.fill"
        case .other: return "pawprint.fill"
        }
    }
}

/// Avatar tint choices mapped onto Theme accent tokens.
enum AvatarTint: String, CaseIterable, Identifiable, Codable {
    case teal, pink, amber, blue, lilac
    var id: String { rawValue }

    var color: Color {
        switch self {
        case .teal: return Theme.accent
        case .pink: return Theme.pink
        case .amber: return Theme.amber
        case .blue: return Theme.blue
        case .lilac: return Theme.lilac
        }
    }

    var label: String { rawValue.capitalized }
}
