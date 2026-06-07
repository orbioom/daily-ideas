import Foundation
import SwiftData

/// Where an FTP value came from.
enum FTPSource: String, CaseIterable, Identifiable {
    case test20min, rampTest, estimate, race
    var id: String { rawValue }

    var label: String {
        switch self {
        case .test20min: return "20-min Test"
        case .rampTest:  return "Ramp Test"
        case .estimate:  return "Estimate"
        case .race:      return "Race Effort"
        }
    }
}

@Model
final class FTPEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var watts: Int = 0
    var sourceRaw: String = FTPSource.test20min.rawValue
    var notes: String = ""

    init(id: UUID = UUID(),
         date: Date = Date(),
         watts: Int = 0,
         source: FTPSource = .test20min,
         notes: String = "") {
        self.id = id
        self.date = date
        self.watts = watts
        self.sourceRaw = source.rawValue
        self.notes = notes
    }

    var source: FTPSource {
        get { FTPSource(rawValue: sourceRaw) ?? .estimate }
        set { sourceRaw = newValue.rawValue }
    }
}
