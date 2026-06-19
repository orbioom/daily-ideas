import Foundation
import SwiftData

@Model
final class HikeSession {
    var id: UUID
    var date: Date
    var durationMinutes: Int
    var distanceKm: Double
    var elevationGainM: Double
    var rating: Int
    var notes: String
    var photoFileName: String?
    var trail: Trail?

    init(
        date: Date = Date(),
        durationMinutes: Int = 60,
        distanceKm: Double = 0,
        elevationGainM: Double = 0,
        rating: Int = 0,
        notes: String = "",
        photoFileName: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.durationMinutes = durationMinutes
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.rating = rating
        self.notes = notes
        self.photoFileName = photoFileName
    }

    var paceMinPerKm: Double? {
        guard distanceKm > 0 else { return nil }
        return Double(durationMinutes) / distanceKm
    }

    var durationFormatted: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
