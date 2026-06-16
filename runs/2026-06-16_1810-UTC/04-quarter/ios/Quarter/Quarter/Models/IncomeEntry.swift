import Foundation
import SwiftData

/// A line of income — feeds the Ledger and (optionally) the Estimate.
@Model
final class IncomeEntry {
    @Attribute(.unique) var id: UUID
    var label: String
    var amount: Double          // money stored as Double per spec
    var date: Date
    var source: String          // "1099", "Other", "W-2", etc.
    var isBusiness: Bool

    init(id: UUID = UUID(),
         label: String,
         amount: Double,
         date: Date = .now,
         source: String = "1099",
         isBusiness: Bool = true) {
        self.id = id
        self.label = label
        self.amount = amount
        self.date = date
        self.source = source
        self.isBusiness = isBusiness
    }
}

/// Common income sources for the picker.
enum IncomeSource: String, CaseIterable, Identifiable {
    case form1099 = "1099"
    case w2 = "W-2"
    case other = "Other"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .form1099: return "doc.text"
        case .w2: return "building.2"
        case .other: return "tray"
        }
    }
}
