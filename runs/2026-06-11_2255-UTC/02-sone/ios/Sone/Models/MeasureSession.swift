import Foundation
import SwiftData

@Model
final class MeasureSession {
    var startedAt: Date
    var duration: TimeInterval
    /// Energy-averaged level (Leq-style) over the session.
    var avgDB: Double
    var minDB: Double
    var maxDB: Double
    /// NIOSH daily noise dose accumulated during this session, percent.
    var dosePercent: Double
    var label: String
    /// Downsampled level trace (~2 samples/sec, capped) for the detail chart.
    var samples: [Double]

    init(startedAt: Date, duration: TimeInterval, avgDB: Double, minDB: Double,
         maxDB: Double, dosePercent: Double, label: String, samples: [Double]) {
        self.startedAt = startedAt
        self.duration = duration
        self.avgDB = avgDB
        self.minDB = minDB
        self.maxDB = maxDB
        self.dosePercent = dosePercent
        self.label = label
        self.samples = samples
    }
}
