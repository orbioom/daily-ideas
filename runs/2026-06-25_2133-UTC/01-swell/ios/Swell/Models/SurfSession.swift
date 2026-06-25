import Foundation
import SwiftData

enum SessionConditions: String, Codable, CaseIterable, Identifiable {
    case epic = "Epic"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .epic: return "flame.fill"
        case .good: return "star.fill"
        case .fair: return "cloud.fill"
        case .poor: return "wind"
        }
    }
}

enum WindDirection: String, Codable, CaseIterable, Identifiable {
    case n = "N", ne = "NE", e = "E", se = "SE"
    case s = "S", sw = "SW", w = "W", nw = "NW"
    case offshore = "Offshore", onshore = "Onshore", crossshore = "Cross"

    var id: String { rawValue }
}

@Model
final class SurfSession {
    var id: UUID = UUID()
    var date: Date = Date.now
    var spotName: String = ""
    var boardName: String = ""
    var durationMinutes: Int = 90
    var waveHeightFt: Double = 3.0
    var swellPeriodSec: Int = 12
    var windSpeedKnots: Double = 10.0
    var windDirection: WindDirection = WindDirection.w
    var conditions: SessionConditions = SessionConditions.good
    var rating: Int = 3
    var notes: String = ""

    init(
        date: Date = .now,
        spotName: String = "",
        boardName: String = "",
        durationMinutes: Int = 90,
        waveHeightFt: Double = 3.0,
        swellPeriodSec: Int = 12,
        windSpeedKnots: Double = 10.0,
        windDirection: WindDirection = .w,
        conditions: SessionConditions = .good,
        rating: Int = 3,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.spotName = spotName
        self.boardName = boardName
        self.durationMinutes = durationMinutes
        self.waveHeightFt = waveHeightFt
        self.swellPeriodSec = swellPeriodSec
        self.windSpeedKnots = windSpeedKnots
        self.windDirection = windDirection
        self.conditions = conditions
        self.rating = rating
        self.notes = notes
    }

    var durationFormatted: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
