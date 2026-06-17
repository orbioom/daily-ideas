import Foundation
import SwiftData

/// A single internal-temperature reading taken during a cook. Celsius canonical.
@Model
final class TempLog {
    @Attribute(.unique) var id: UUID
    var time: Date
    var internalTempC: Double
    var note: String
    var cook: Cook?

    init(id: UUID = UUID(),
         time: Date = Date(),
         internalTempC: Double,
         note: String = "") {
        self.id = id
        self.time = time
        self.internalTempC = internalTempC
        self.note = note
    }
}
