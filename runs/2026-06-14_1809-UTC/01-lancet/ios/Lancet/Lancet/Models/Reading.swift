import Foundation
import SwiftData

/// A single glucose reading. Value is stored canonically in mg/dL.
@Model
final class Reading {
    @Attribute(.unique) var id: UUID
    /// Canonical blood-glucose value in mg/dL.
    var valueMgdl: Double
    /// Stored raw string for SwiftData stability; access via `context`.
    var contextRaw: String
    /// Optional carbohydrate intake in grams.
    var carbs: Double?
    /// Optional insulin dose in units.
    var insulinUnits: Double?
    var note: String
    var date: Date

    init(valueMgdl: Double,
         context: ReadingContext,
         carbs: Double? = nil,
         insulinUnits: Double? = nil,
         note: String = "",
         date: Date = .now) {
        self.id = UUID()
        self.valueMgdl = valueMgdl
        self.contextRaw = context.rawValue
        self.carbs = carbs
        self.insulinUnits = insulinUnits
        self.note = note
        self.date = date
    }

    /// Typed accessor for the persisted context. Falls back to `.random` if unrecognized.
    var context: ReadingContext {
        get { ReadingContext(rawValue: contextRaw) ?? .random }
        set { contextRaw = newValue.rawValue }
    }

    /// The logbook column this reading belongs to, resolving time-of-day for meal contexts.
    var resolvedSlot: MealSlot {
        if let mapped = context.slot { return mapped }
        // For before/after meal, exercise, random: place by hour of day.
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 4..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<21: return .dinner
        case 21..<24, 0..<4: return .bedtime
        default: return .other
        }
    }
}
