import Foundation
import SwiftData

enum Partner: String, CaseIterable, Codable, Identifiable {
    case a = "A"
    case b = "B"
    var id: String { rawValue }
    var other: Partner { self == .a ? .b : .a }
}

enum Decision: String, CaseIterable, Codable {
    case like, pass, superlike

    var label: String {
        switch self {
        case .like: return "Like"
        case .pass: return "Pass"
        case .superlike: return "Love it"
        }
    }
}

/// One partner's call on one name. At most one verdict per (name, partner) —
/// re-deciding replaces the old verdict.
@Model
final class Verdict {
    var nameID: String
    var partnerRaw: String
    var decisionRaw: String
    var date: Date

    init(nameID: String, partner: Partner, decision: Decision, date: Date = Date()) {
        self.nameID = nameID
        self.partnerRaw = partner.rawValue
        self.decisionRaw = decision.rawValue
        self.date = date
    }

    var partner: Partner { Partner(rawValue: partnerRaw) ?? .a }
    var decision: Decision { Decision(rawValue: decisionRaw) ?? .pass }
}
