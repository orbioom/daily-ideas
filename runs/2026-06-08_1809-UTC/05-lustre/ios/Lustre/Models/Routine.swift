import Foundation
import SwiftData

enum RoutineKind: String, CaseIterable, Identifiable, Codable {
    case am, pm, weekly
    var id: String { rawValue }
    var title: String {
        switch self {
        case .am: return "Morning"
        case .pm: return "Evening"
        case .weekly: return "Weekly"
        }
    }
    var icon: String {
        switch self {
        case .am: return "sunrise.fill"
        case .pm: return "moon.stars.fill"
        case .weekly: return "calendar.badge.clock"
        }
    }
}

/// One ordered step in a routine. May reference a product on the shelf, or be a
/// free-text custom step. `uuid` is a stable key for daily completion logs.
@Model
final class RoutineStep {
    var uuid: String
    var routineRaw: String
    var order: Int
    var customLabel: String
    var instruction: String
    var product: Product?

    init(routine: RoutineKind,
         order: Int,
         product: Product? = nil,
         customLabel: String = "",
         instruction: String = "") {
        self.uuid = UUID().uuidString
        self.routineRaw = routine.rawValue
        self.order = order
        self.product = product
        self.customLabel = customLabel
        self.instruction = instruction
    }

    var routine: RoutineKind {
        get { RoutineKind(rawValue: routineRaw) ?? .am }
        set { routineRaw = newValue.rawValue }
    }

    var displayName: String {
        if let p = product { return p.name }
        return customLabel.isEmpty ? "Step" : customLabel
    }

    var displayCategory: String {
        if let p = product { return p.category.title }
        return "Custom"
    }
}

/// A per-day record of which steps of a routine were completed.
@Model
final class RoutineLog {
    var date: Date            // start of day
    var routineRaw: String
    var doneStepUUIDs: [String]

    init(date: Date, routine: RoutineKind, doneStepUUIDs: [String] = []) {
        self.date = Calendar.current.startOfDay(for: date)
        self.routineRaw = routine.rawValue
        self.doneStepUUIDs = doneStepUUIDs
    }

    var routine: RoutineKind {
        get { RoutineKind(rawValue: routineRaw) ?? .am }
        set { routineRaw = newValue.rawValue }
    }
}

/// A photo-free skin journal entry.
@Model
final class SkinLog {
    var date: Date
    var rating: Int            // 1...5 overall skin feeling
    var concernsRaw: [String]
    var note: String

    init(date: Date = .now, rating: Int = 3, concerns: [SkinConcern] = [], note: String = "") {
        self.date = date
        self.rating = min(max(rating, 1), 5)
        self.concernsRaw = concerns.map { $0.rawValue }
        self.note = note
    }

    var concerns: [SkinConcern] {
        get { concernsRaw.compactMap { SkinConcern(rawValue: $0) } }
        set { concernsRaw = newValue.map { $0.rawValue } }
    }
}

enum SkinConcern: String, CaseIterable, Identifiable, Codable {
    case dryness, oiliness, breakout, redness, dullness, irritation, texture, calm

    var id: String { rawValue }
    var title: String {
        switch self {
        case .dryness: return "Dryness"
        case .oiliness: return "Oiliness"
        case .breakout: return "Breakout"
        case .redness: return "Redness"
        case .dullness: return "Dullness"
        case .irritation: return "Irritation"
        case .texture: return "Texture"
        case .calm: return "Calm & clear"
        }
    }
    var icon: String {
        switch self {
        case .dryness: return "wind"
        case .oiliness: return "drop.fill"
        case .breakout: return "circle.grid.cross"
        case .redness: return "flame"
        case .dullness: return "cloud"
        case .irritation: return "exclamationmark.triangle"
        case .texture: return "circle.hexagongrid"
        case .calm: return "checkmark.seal"
        }
    }
}
