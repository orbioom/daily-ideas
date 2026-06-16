import Foundation
import SwiftData

/// A saved tinnitus tone match — the frequency the user dialed in to match their ringing.
@Model
final class TinnitusMatch {
    var date: Date
    var frequency: Double
    var earRaw: String
    var note: String

    init(date: Date = .now, frequency: Double, ear: Ear, note: String = "") {
        self.date = date
        self.frequency = frequency
        self.earRaw = ear.rawValue
        self.note = note
    }

    var ear: Ear { Ear(rawValue: earRaw) ?? .right }
}
