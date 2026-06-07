import Foundation
import SwiftData

enum CookState: String, Codable {
    case cooking, done
}

/// A cook — either currently in the bath (with a live countdown) or a finished
/// record in the log.
@Model
final class Cook {
    var foodName: String
    var category: String
    var shapeRaw: String
    var thicknessMM: Double
    var bathC: Double
    var startStateRaw: String
    var logReductions: Double
    var comeUpMinutes: Double
    var pasteurizeMinutes: Double
    var totalMinutes: Double
    var startedAt: Date
    var stateRaw: String
    var rating: Int
    var isFavorite: Bool
    var notes: String

    init(foodName: String, category: String = "", shape: FoodShape = .slab,
         thicknessMM: Double = 25, bathC: Double = 54.5, startState: StartState = .fridge,
         logReductions: Double = 6.5, comeUpMinutes: Double = 0, pasteurizeMinutes: Double = 0,
         totalMinutes: Double = 0, startedAt: Date = .now, state: CookState = .cooking,
         rating: Int = 0, isFavorite: Bool = false, notes: String = "") {
        self.foodName = foodName
        self.category = category
        self.shapeRaw = shape.rawValue
        self.thicknessMM = thicknessMM
        self.bathC = bathC
        self.startStateRaw = startState.rawValue
        self.logReductions = logReductions
        self.comeUpMinutes = comeUpMinutes
        self.pasteurizeMinutes = pasteurizeMinutes
        self.totalMinutes = totalMinutes
        self.startedAt = startedAt
        self.stateRaw = state.rawValue
        self.rating = rating
        self.isFavorite = isFavorite
        self.notes = notes
    }

    var shape: FoodShape { FoodShape(rawValue: shapeRaw) ?? .slab }
    var startState: StartState { StartState(rawValue: startStateRaw) ?? .fridge }
    var state: CookState {
        get { CookState(rawValue: stateRaw) ?? .done }
        set { stateRaw = newValue.rawValue }
    }

    /// The moment the cook is ready.
    var readyAt: Date { startedAt.addingTimeInterval(totalMinutes * 60) }

    /// Seconds remaining (negative once ready).
    func secondsRemaining(now: Date = .now) -> Double {
        readyAt.timeIntervalSince(now)
    }

    /// Progress 0...1 through the cook.
    func progress(now: Date = .now) -> Double {
        guard totalMinutes > 0 else { return 1 }
        let elapsed = now.timeIntervalSince(startedAt) / 60.0
        return min(1, max(0, elapsed / totalMinutes))
    }

    var isReady: Bool { secondsRemaining() <= 0 }
}
