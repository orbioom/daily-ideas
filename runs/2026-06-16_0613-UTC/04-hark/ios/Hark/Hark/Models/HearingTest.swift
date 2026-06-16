import Foundation
import SwiftData

/// A completed screening session. Thresholds are stored via the child `Threshold` model.
@Model
final class HearingTest {
    var date: Date
    /// Cached PTA per ear (nil if not measurable). Stored so History/trend stay cheap.
    var ptaLeft: Double?
    var ptaRight: Double?
    /// The relative max level used when this test was run (for context/display).
    var maxLevelUsed: Double

    @Relationship(deleteRule: .cascade, inverse: \Threshold.test)
    var thresholds: [Threshold]

    init(date: Date = .now, maxLevelUsed: Double = 80, ptaLeft: Double? = nil, ptaRight: Double? = nil) {
        self.date = date
        self.maxLevelUsed = maxLevelUsed
        self.ptaLeft = ptaLeft
        self.ptaRight = ptaRight
        self.thresholds = []
    }

    /// Threshold dictionary for one ear: [frequency: dbLevel].
    func thresholdMap(for ear: Ear) -> [Int: Double] {
        var map: [Int: Double] = [:]
        for t in thresholds where t.earRaw == ear.rawValue {
            map[t.frequency] = t.dbLevel
        }
        return map
    }

    func analysis(for ear: Ear) -> EarAnalysis {
        let map = thresholdMap(for: ear)
        return EarAnalysis(ear: ear, thresholds: map, pta: ear == .left ? ptaLeft : ptaRight)
    }
}

/// One measured threshold (lowest heard level) at a given frequency for one ear.
@Model
final class Threshold {
    var earRaw: String
    var frequency: Int
    /// Measured level in Hark's relative dB-HL-ish scale. nil-able is avoided; "not measurable"
    /// is represented by simply not creating a row for that frequency.
    var dbLevel: Double
    var test: HearingTest?

    init(ear: Ear, frequency: Int, dbLevel: Double, test: HearingTest? = nil) {
        self.earRaw = ear.rawValue
        self.frequency = frequency
        self.dbLevel = dbLevel
        self.test = test
    }

    var ear: Ear { Ear(rawValue: earRaw) ?? .right }
}
