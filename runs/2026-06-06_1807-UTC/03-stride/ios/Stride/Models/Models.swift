import Foundation
import SwiftData

/// The type of run, for filtering and weekly summaries.
enum RunKind: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy", long = "Long", tempo = "Tempo", interval = "Interval", race = "Race"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .easy: return "figure.walk"; case .long: return "figure.run"
        case .tempo: return "speedometer"; case .interval: return "stopwatch"; case .race: return "flag.checkered"
        }
    }
}

/// A logged run or race.
@Model
final class Run {
    var name: String
    var date: Date
    var distanceMeters: Double
    var durationSeconds: Double
    var kindRaw: String
    var rpe: Int               // perceived effort 1–10
    var notes: String

    init(name: String, date: Date = .now, distanceMeters: Double, durationSeconds: Double,
         kind: RunKind = .easy, rpe: Int = 5, notes: String = "") {
        self.name = name
        self.date = date
        self.distanceMeters = max(0, distanceMeters)
        self.durationSeconds = max(0, durationSeconds)
        self.kindRaw = kind.rawValue
        self.rpe = min(10, max(1, rpe))
        self.notes = notes
    }

    var kind: RunKind {
        get { RunKind(rawValue: kindRaw) ?? .easy }
        set { kindRaw = newValue.rawValue }
    }
    /// Pace in seconds per km.
    var paceSecPerKm: Double {
        guard distanceMeters > 0 else { return 0 }
        return durationSeconds / (distanceMeters / 1000.0)
    }
    var vdot: Double { PaceMath.vdot(distance: distanceMeters, timeSec: durationSeconds) }
}
