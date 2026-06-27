import SwiftData
import Foundation

enum WorkoutType: String, CaseIterable, Codable {
    case distance = "Distance"
    case timed = "Timed"
    case intervals = "Intervals"
    case freerow = "Free Row"

    var icon: String {
        switch self {
        case .distance: return "ruler"
        case .timed: return "stopwatch"
        case .intervals: return "repeat"
        case .freerow: return "figure.rowing"
        }
    }
}

enum StrokeRating: Int, CaseIterable, Codable {
    case one = 1, two, three, four, five
    var label: String { String(repeating: "★", count: rawValue) }
}

struct WorkoutInterval: Codable, Identifiable {
    var id: UUID = UUID()
    var number: Int
    var distanceM: Int
    var timeSeconds: Int
    var splitSeconds: Int
    var strokeRate: Int
    var watts: Double

    var split500mDisplay: String { RowEngine.formatSplit(splitSeconds) }
}

@Model
final class RowWorkout {
    var id: UUID
    var date: Date
    var workoutTypeRaw: String
    var distanceM: Int
    var timeSeconds: Int
    var avgSplitSeconds: Int
    var avgStrokeRate: Int
    var avgWatts: Double
    var ratingRaw: Int
    var notes: String
    var intervalsData: Data

    init(
        date: Date = Date(),
        type: WorkoutType = .distance,
        distanceM: Int,
        timeSeconds: Int,
        avgSplitSeconds: Int,
        avgStrokeRate: Int = 0,
        avgWatts: Double = 0,
        rating: StrokeRating = .three,
        notes: String = "",
        intervals: [WorkoutInterval] = []
    ) {
        self.id = UUID()
        self.date = date
        self.workoutTypeRaw = type.rawValue
        self.distanceM = distanceM
        self.timeSeconds = timeSeconds
        self.avgSplitSeconds = avgSplitSeconds
        self.avgStrokeRate = avgStrokeRate
        self.avgWatts = avgWatts
        self.ratingRaw = rating.rawValue
        self.notes = notes
        self.intervalsData = (try? JSONEncoder().encode(intervals)) ?? Data()
    }

    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .distance }
        set { workoutTypeRaw = newValue.rawValue }
    }

    var rating: StrokeRating {
        get { StrokeRating(rawValue: ratingRaw) ?? .three }
        set { ratingRaw = newValue.rawValue }
    }

    var intervals: [WorkoutInterval] {
        get { (try? JSONDecoder().decode([WorkoutInterval].self, from: intervalsData)) ?? [] }
        set { intervalsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var split500mDisplay: String { RowEngine.formatSplit(avgSplitSeconds) }
    var durationDisplay: String { RowEngine.formatDuration(timeSeconds) }
    var distanceDisplay: String {
        distanceM >= 1000 ? String(format: "%.1f km", Double(distanceM) / 1000) : "\(distanceM) m"
    }
}
