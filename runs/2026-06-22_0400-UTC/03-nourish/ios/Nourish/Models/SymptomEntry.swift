import Foundation
import SwiftData

@Model
final class SymptomEntry {
    var id: UUID
    var date: Date
    var symptomName: String
    var severity: Int
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        symptomName: String,
        severity: Int = 3,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.symptomName = symptomName
        self.severity = max(1, min(5, severity))
        self.notes = notes
    }
}

// MARK: - Severity helpers

extension SymptomEntry {
    var severityLabel: String {
        switch severity {
        case 1: return "Very Mild"
        case 2: return "Mild"
        case 3: return "Moderate"
        case 4: return "Severe"
        case 5: return "Very Severe"
        default: return "Unknown"
        }
    }

    var severityColor: String {
        switch severity {
        case 1, 2: return "safeColor"
        case 3: return "cornColor"
        case 4, 5: return "terra"
        default: return "secondaryText"
        }
    }
}
