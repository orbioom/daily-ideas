import Foundation
import SwiftData

@Model
final class PlannedRun {
    var id: UUID
    var weekNumber: Int
    var dayOfWeek: Int           // 0=Mon, 6=Sun
    var runType: String
    var distanceKm: Double
    var paceTargetSecondsPerKm: Double
    var notes: String
    var isCompleted: Bool
    var completedDate: Date?
    var actualDistanceKm: Double
    var actualDurationSeconds: Int

    init(
        id: UUID = UUID(),
        weekNumber: Int,
        dayOfWeek: Int,
        runType: String,
        distanceKm: Double,
        paceTargetSecondsPerKm: Double = 0,
        notes: String = "",
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        actualDistanceKm: Double = 0,
        actualDurationSeconds: Int = 0
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.dayOfWeek = dayOfWeek
        self.runType = runType
        self.distanceKm = distanceKm
        self.paceTargetSecondsPerKm = paceTargetSecondsPerKm
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.actualDistanceKm = actualDistanceKm
        self.actualDurationSeconds = actualDurationSeconds
    }

    var type: RunType {
        RunType(rawValue: runType) ?? .rest
    }
}

enum RunType: String, CaseIterable {
    case easy = "easy"
    case long = "long"
    case tempo = "tempo"
    case interval = "interval"
    case racePace = "racePace"
    case crossTrain = "crossTrain"
    case rest = "rest"

    var displayName: String {
        switch self {
        case .easy: return "Easy Run"
        case .long: return "Long Run"
        case .tempo: return "Tempo Run"
        case .interval: return "Intervals"
        case .racePace: return "Race Pace"
        case .crossTrain: return "Cross Train"
        case .rest: return "Rest"
        }
    }

    var shortName: String {
        switch self {
        case .easy: return "E"
        case .long: return "L"
        case .tempo: return "T"
        case .interval: return "I"
        case .racePace: return "RP"
        case .crossTrain: return "X"
        case .rest: return "R"
        }
    }

    var description: String {
        switch self {
        case .easy: return "Conversational pace, aerobic base building"
        case .long: return "60-90s slower than goal pace, endurance focus"
        case .tempo: return "Comfortably hard, lactate threshold pace"
        case .interval: return "Short fast bursts with recovery jogs"
        case .racePace: return "Goal marathon pace effort"
        case .crossTrain: return "Low-impact: swimming, cycling, or yoga"
        case .rest: return "Full recovery, no running"
        }
    }

    var isRunningWorkout: Bool {
        switch self {
        case .easy, .long, .tempo, .interval, .racePace: return true
        case .crossTrain, .rest: return false
        }
    }

    var systemImage: String {
        switch self {
        case .easy: return "figure.run"
        case .long: return "figure.run.circle"
        case .tempo: return "flame"
        case .interval: return "bolt"
        case .racePace: return "flag.checkered"
        case .crossTrain: return "figure.cross.training"
        case .rest: return "moon.zzz"
        }
    }
}
