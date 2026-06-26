import SwiftData
import Foundation

@Model
final class SwimPool {
    var id: UUID
    var name: String
    var lengthMeters: Double
    var poolType: String // "indoor", "outdoor", "openWater"
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \SwimSession.pool)
    var sessions: [SwimSession]

    init(
        name: String,
        lengthMeters: Double = 25,
        poolType: String = "indoor",
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.lengthMeters = lengthMeters
        self.poolType = poolType
        self.notes = notes
        self.createdAt = Date()
        self.sessions = []
    }
}

@Model
final class SwimSession {
    var id: UUID
    var date: Date
    var totalDistanceMeters: Double
    var durationSeconds: Int
    var pool: SwimPool?
    var notes: String
    var feelRating: Int // 1-5
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SwimSet.session)
    var sets: [SwimSet]

    init(
        date: Date = Date(),
        totalDistanceMeters: Double = 0,
        durationSeconds: Int = 0,
        pool: SwimPool? = nil,
        notes: String = "",
        feelRating: Int = 3
    ) {
        self.id = UUID()
        self.date = date
        self.totalDistanceMeters = totalDistanceMeters
        self.durationSeconds = durationSeconds
        self.pool = pool
        self.notes = notes
        self.feelRating = feelRating
        self.createdAt = Date()
        self.sets = []
    }

    var computedDistance: Double {
        sets.reduce(0) { $0 + $1.distanceMeters }
    }

    var computedDuration: Int {
        sets.reduce(0) { $0 + $1.durationSeconds + $1.restSeconds }
    }
}

@Model
final class SwimSet {
    var id: UUID
    var sortOrder: Int
    var strokeType: String // "freestyle","backstroke","breaststroke","butterfly","im","kick","pull","drill"
    var distanceMeters: Double
    var repetitions: Int
    var durationSeconds: Int
    var restSeconds: Int
    var intensityLevel: String // "easy","moderate","hard","race"
    var notes: String
    var session: SwimSession?

    init(
        sortOrder: Int = 0,
        strokeType: String = "freestyle",
        distanceMeters: Double = 100,
        repetitions: Int = 1,
        durationSeconds: Int = 0,
        restSeconds: Int = 30,
        intensityLevel: String = "moderate",
        notes: String = ""
    ) {
        self.id = UUID()
        self.sortOrder = sortOrder
        self.strokeType = strokeType
        self.distanceMeters = distanceMeters
        self.repetitions = repetitions
        self.durationSeconds = durationSeconds
        self.restSeconds = restSeconds
        self.intensityLevel = intensityLevel
        self.notes = notes
    }

    var totalDistanceMeters: Double { distanceMeters * Double(max(repetitions, 1)) }

    var pace100m: Double? {
        guard durationSeconds > 0, distanceMeters > 0 else { return nil }
        let totalSec = Double(durationSeconds)
        return (totalSec / totalDistanceMeters) * 100.0
    }
}

@Model
final class SplashSettings {
    var id: UUID
    var useYards: Bool
    var defaultPoolLength: Double
    var hapticsEnabled: Bool
    var hasSeenOnboarding: Bool
    var defaultIntensity: String
    var weeklyGoalKm: Double

    init() {
        self.id = UUID()
        self.useYards = false
        self.defaultPoolLength = 25
        self.hapticsEnabled = true
        self.hasSeenOnboarding = false
        self.defaultIntensity = "moderate"
        self.weeklyGoalKm = 3.0
    }
}
