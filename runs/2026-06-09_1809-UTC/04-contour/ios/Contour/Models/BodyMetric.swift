import Foundation
import SwiftData

/// A single body measurement reading. Values are stored canonical: kg for
/// weight, cm for lengths, % for body fat. Display conversion is done by `Units`.
@Model
final class BodyMetric {
    var date: Date
    var typeRaw: String
    var value: Double
    var note: String
    var createdAt: Date

    init(date: Date = .now,
         type: MetricType = .weight,
         value: Double = 0,
         note: String = "") {
        self.date = date
        self.typeRaw = type.rawValue
        self.value = value
        self.note = note
        self.createdAt = .now
    }

    var type: MetricType {
        get { MetricType(rawValue: typeRaw) ?? .weight }
        set { typeRaw = newValue.rawValue }
    }
}
