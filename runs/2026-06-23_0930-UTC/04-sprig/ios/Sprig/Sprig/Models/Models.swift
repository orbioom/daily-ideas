import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums

/// Which breast a nursing feed used, or whether it was a bottle.
enum FeedKind: String, Codable, CaseIterable, Identifiable {
    case breastLeft
    case breastRight
    case breastBoth
    case bottle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breastLeft: return "Left"
        case .breastRight: return "Right"
        case .breastBoth: return "Both"
        case .bottle: return "Bottle"
        }
    }

    var shortLabel: String {
        switch self {
        case .breastLeft: return "L"
        case .breastRight: return "R"
        case .breastBoth: return "L+R"
        case .bottle: return "Btl"
        }
    }

    var systemImage: String {
        switch self {
        case .bottle: return "waterbottle.fill"
        default: return "drop.fill"
        }
    }

    var isBreast: Bool { self != .bottle }
}

/// Type of diaper change.
enum DiaperKind: String, Codable, CaseIterable, Identifiable {
    case wet
    case dirty
    case mixed
    case dry

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wet: return "Wet"
        case .dirty: return "Dirty"
        case .mixed: return "Mixed"
        case .dry: return "Dry"
        }
    }

    var systemImage: String {
        switch self {
        case .wet: return "drop.fill"
        case .dirty: return "circle.fill"
        case .mixed: return "circle.lefthalf.filled"
        case .dry: return "checkmark.circle.fill"
        }
    }
}

/// Units the parent prefers for bottles.
enum VolumeUnit: String, Codable, CaseIterable, Identifiable {
    case oz
    case ml

    var id: String { rawValue }
    var label: String { self == .oz ? "fl oz" : "mL" }

    /// Convert a stored milliliter value into the display unit.
    func display(fromML ml: Double) -> Double {
        self == .ml ? ml : ml / 29.5735
    }

    /// Convert a display value back to stored milliliters.
    func toML(_ value: Double) -> Double {
        self == .ml ? value : value * 29.5735
    }

    var step: Double { self == .oz ? 0.5 : 10 }
    var maxValue: Double { self == .oz ? 16 : 480 }
}

/// Units the parent prefers for weight.
enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg
    case lb

    var id: String { rawValue }
    var label: String { self == .kg ? "kg" : "lb" }

    func display(fromGrams grams: Double) -> Double {
        self == .kg ? grams / 1000 : grams / 453.592
    }

    func toGrams(_ value: Double) -> Double {
        self == .kg ? value * 1000 : value * 453.592
    }
}

/// Units the parent prefers for length.
enum LengthUnit: String, Codable, CaseIterable, Identifiable {
    case cm
    case inch

    var id: String { rawValue }
    var label: String { self == .cm ? "cm" : "in" }

    func display(fromCM cm: Double) -> Double {
        self == .cm ? cm : cm / 2.54
    }

    func toCM(_ value: Double) -> Double {
        self == .cm ? value : value * 2.54
    }
}

// MARK: - Models

/// A baby profile. Owns its logs via cascade relationships.
@Model
final class Baby {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date
    /// Stored as a hex-ish RGB triplet packed for a swatch tint.
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FeedLog.baby)
    var feeds: [FeedLog]

    @Relationship(deleteRule: .cascade, inverse: \SleepLog.baby)
    var sleeps: [SleepLog]

    @Relationship(deleteRule: .cascade, inverse: \DiaperLog.baby)
    var diapers: [DiaperLog]

    @Relationship(deleteRule: .cascade, inverse: \GrowthEntry.baby)
    var growth: [GrowthEntry]

    init(name: String, birthDate: Date, colorHex: String = "3F8F7A") {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.colorHex = colorHex
        self.createdAt = Date()
        self.feeds = []
        self.sleeps = []
        self.diapers = []
        self.growth = []
    }
}

/// A single feeding event.
@Model
final class FeedLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var kindRaw: String
    /// Duration in seconds for breast feeds (0 for bottle).
    var durationSeconds: Int
    /// Volume in milliliters for bottle feeds (0 for breast).
    var volumeML: Double
    var note: String
    var baby: Baby?

    init(date: Date, kind: FeedKind, durationSeconds: Int = 0, volumeML: Double = 0, note: String = "") {
        self.id = UUID()
        self.date = date
        self.kindRaw = kind.rawValue
        self.durationSeconds = max(0, durationSeconds)
        self.volumeML = max(0, volumeML)
        self.note = note
    }

    var kind: FeedKind {
        get { FeedKind(rawValue: kindRaw) ?? .breastBoth }
        set { kindRaw = newValue.rawValue }
    }
}

/// A sleep session.
@Model
final class SleepLog {
    @Attribute(.unique) var id: UUID
    var start: Date
    /// Nil while the session is ongoing.
    var end: Date?
    var note: String
    var baby: Baby?

    init(start: Date, end: Date? = nil, note: String = "") {
        self.id = UUID()
        self.start = start
        self.end = end
        self.note = note
    }

    var isOngoing: Bool { end == nil }

    /// Duration in seconds; for ongoing sessions, measured to `now`.
    func duration(now: Date = Date()) -> TimeInterval {
        let finish = end ?? now
        return max(0, finish.timeIntervalSince(start))
    }
}

/// A diaper change.
@Model
final class DiaperLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var kindRaw: String
    var note: String
    var baby: Baby?

    init(date: Date, kind: DiaperKind, note: String = "") {
        self.id = UUID()
        self.date = date
        self.kindRaw = kind.rawValue
        self.note = note
    }

    var kind: DiaperKind {
        get { DiaperKind(rawValue: kindRaw) ?? .wet }
        set { kindRaw = newValue.rawValue }
    }
}

/// A growth measurement (weight and/or length).
@Model
final class GrowthEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Weight in grams (0 if not recorded).
    var weightGrams: Double
    /// Length in centimeters (0 if not recorded).
    var lengthCM: Double
    var note: String
    var baby: Baby?

    init(date: Date, weightGrams: Double = 0, lengthCM: Double = 0, note: String = "") {
        self.id = UUID()
        self.date = date
        self.weightGrams = max(0, weightGrams)
        self.lengthCM = max(0, lengthCM)
        self.note = note
    }

    var hasWeight: Bool { weightGrams > 0 }
    var hasLength: Bool { lengthCM > 0 }
}
