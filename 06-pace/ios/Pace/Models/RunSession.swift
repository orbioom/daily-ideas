import Foundation
import SwiftData

enum ActivityType: String, CaseIterable, Codable {
    case run = "Run"
    case walk = "Walk"
    case hike = "Hike"

    var systemImage: String {
        switch self {
        case .run: return "figure.run"
        case .walk: return "figure.walk"
        case .hike: return "figure.hiking"
        }
    }
}

@Model
final class RunSession {
    var id: UUID
    var date: Date
    var activityType: ActivityType
    var name: String
    var duration: TimeInterval
    var distanceMeters: Double
    var elevationGainMeters: Double
    var averageSpeedMps: Double
    var maxSpeedMps: Double
    var calories: Double
    var averageHeartRate: Double?
    var notes: String
    @Relationship(deleteRule: .cascade) var points: [RoutePoint]

    init(activityType: ActivityType = .run) {
        self.id = UUID()
        self.date = .now
        self.activityType = activityType
        self.name = ""
        self.duration = 0
        self.distanceMeters = 0
        self.elevationGainMeters = 0
        self.averageSpeedMps = 0
        self.maxSpeedMps = 0
        self.calories = 0
        self.notes = ""
        self.points = []
    }

    var distanceKm: Double { distanceMeters / 1000 }
    var distanceMiles: Double { distanceMeters / 1609.344 }

    var paceSecondsPerKm: Double {
        guard distanceKm > 0 else { return 0 }
        return duration / distanceKm
    }

    var paceSecondsPerMile: Double {
        guard distanceMiles > 0 else { return 0 }
        return duration / distanceMiles
    }

    var durationFormatted: String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        let s = Int(duration) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    func paceFormatted(useKm: Bool) -> String {
        let paceSeconds = useKm ? paceSecondsPerKm : paceSecondsPerMile
        guard paceSeconds > 0 && paceSeconds < 3600 else { return "--:--" }
        let m = Int(paceSeconds) / 60
        let s = Int(paceSeconds) % 60
        return String(format: "%d:%02d", m, s)
    }

    func distanceFormatted(useKm: Bool) -> String {
        if useKm {
            return String(format: "%.2f km", distanceKm)
        } else {
            return String(format: "%.2f mi", distanceMiles)
        }
    }

    var coordinatesForMap: [(Double, Double)] {
        points.sorted { $0.timestamp < $1.timestamp }.map { ($0.latitude, $0.longitude) }
    }
}
