import Foundation
import SwiftData

/// The kind of loan a scenario represents. Stored as a raw `String` on the model
/// (per SwiftData guidance) and exposed as a computed enum for icon/label.
enum LoanType: String, CaseIterable, Identifiable, Hashable {
    case mortgage
    case auto
    case student
    case personal

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mortgage: return "Mortgage"
        case .auto:     return "Auto"
        case .student:  return "Student"
        case .personal: return "Personal"
        }
    }

    /// SF Symbol name used across the app for this loan type.
    var symbol: String {
        switch self {
        case .mortgage: return "house.fill"
        case .auto:     return "car.fill"
        case .student:  return "graduationcap.fill"
        case .personal: return "creditcard.fill"
        }
    }

    /// A sensible default term in months for this loan type.
    var defaultTermMonths: Int {
        switch self {
        case .mortgage: return 360
        case .auto:     return 60
        case .student:  return 120
        case .personal: return 36
        }
    }
}

/// A saved loan scenario. The single persisted user-owned entity in Abacus.
@Model
final class LoanScenario {
    @Attribute(.unique) var id: UUID
    var name: String
    var loanTypeRaw: String
    var principal: Double
    var annualRatePct: Double
    var termMonths: Int
    var startDate: Date
    var extraMonthly: Double
    var extraOneTime: Double
    var extraOneTimeMonth: Int
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String = "Untitled loan",
         loanType: LoanType = .mortgage,
         principal: Double = 0,
         annualRatePct: Double = 0,
         termMonths: Int = 360,
         startDate: Date = .now,
         extraMonthly: Double = 0,
         extraOneTime: Double = 0,
         extraOneTimeMonth: Int = 0,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.loanTypeRaw = loanType.rawValue
        self.principal = principal
        self.annualRatePct = annualRatePct
        self.termMonths = termMonths
        self.startDate = startDate
        self.extraMonthly = extraMonthly
        self.extraOneTime = extraOneTime
        self.extraOneTimeMonth = extraOneTimeMonth
        self.createdAt = createdAt
    }

    /// Typed accessor for the stored raw loan type, with a safe fallback.
    var loanType: LoanType {
        get { LoanType(rawValue: loanTypeRaw) ?? .mortgage }
        set { loanTypeRaw = newValue.rawValue }
    }

    /// A computed summary for this scenario (uses the pure engine).
    var summary: LoanSummary {
        LoanMath.summarize(principal: principal,
                           annualRatePct: annualRatePct,
                           termMonths: termMonths,
                           startDate: startDate,
                           extraMonthly: extraMonthly,
                           extraOneTime: extraOneTime,
                           extraOneTimeMonth: extraOneTimeMonth)
    }
}
