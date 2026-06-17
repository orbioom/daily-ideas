import Foundation

/// 2025 US federal & FICA constants plus a curated state effective-rate table.
///
/// IMPORTANT: These figures power an *estimate*. They are not tax advice.
/// State rates are single representative flat effective approximations, not the
/// actual progressive schedules each state uses. See `Disclaimer` in the UI.
enum TaxTables2025 {

    // MARK: - A single progressive bracket

    /// A marginal tax bracket: `rate` applies to taxable income above `lowerBound`
    /// (and up to the next bracket's lower bound).
    struct Bracket {
        let lowerBound: Decimal
        let rate: Decimal   // e.g. 0.22 for 22%
    }

    // MARK: - Standard deduction (2025)

    static func standardDeduction(_ status: FilingStatus) -> Decimal {
        switch status {
        case .single:           return 15_000
        case .marriedJoint:     return 30_000
        case .marriedSeparate:  return 15_000
        case .headOfHousehold:  return 22_500
        }
    }

    // MARK: - Federal income tax brackets (2025), per filing status
    //
    // Edges hard-coded from the 2025 IRS inflation-adjusted schedules.
    // The first bracket always starts at 0.

    static func federalBrackets(_ status: FilingStatus) -> [Bracket] {
        switch status {
        case .single:
            return [
                Bracket(lowerBound: 0,        rate: 0.10),
                Bracket(lowerBound: 11_925,   rate: 0.12),
                Bracket(lowerBound: 48_475,   rate: 0.22),
                Bracket(lowerBound: 103_350,  rate: 0.24),
                Bracket(lowerBound: 197_300,  rate: 0.32),
                Bracket(lowerBound: 250_525,  rate: 0.35),
                Bracket(lowerBound: 626_350,  rate: 0.37)
            ]
        case .marriedJoint:
            return [
                Bracket(lowerBound: 0,        rate: 0.10),
                Bracket(lowerBound: 23_850,   rate: 0.12),
                Bracket(lowerBound: 96_950,   rate: 0.22),
                Bracket(lowerBound: 206_700,  rate: 0.24),
                Bracket(lowerBound: 394_600,  rate: 0.32),
                Bracket(lowerBound: 501_050,  rate: 0.35),
                Bracket(lowerBound: 751_600,  rate: 0.37)
            ]
        case .marriedSeparate:
            return [
                Bracket(lowerBound: 0,        rate: 0.10),
                Bracket(lowerBound: 11_925,   rate: 0.12),
                Bracket(lowerBound: 48_475,   rate: 0.22),
                Bracket(lowerBound: 103_350,  rate: 0.24),
                Bracket(lowerBound: 197_300,  rate: 0.32),
                Bracket(lowerBound: 250_525,  rate: 0.35),
                Bracket(lowerBound: 375_800,  rate: 0.37)
            ]
        case .headOfHousehold:
            return [
                Bracket(lowerBound: 0,        rate: 0.10),
                Bracket(lowerBound: 17_000,   rate: 0.12),
                Bracket(lowerBound: 64_850,   rate: 0.22),
                Bracket(lowerBound: 103_350,  rate: 0.24),
                Bracket(lowerBound: 197_300,  rate: 0.32),
                Bracket(lowerBound: 250_500,  rate: 0.35),
                Bracket(lowerBound: 626_350,  rate: 0.37)
            ]
        }
    }

    // MARK: - FICA (2025)

    /// Social Security tax rate (employee share).
    static let socialSecurityRate: Decimal = 0.062
    /// 2025 Social Security taxable wage base.
    static let socialSecurityWageBase: Decimal = 176_100
    /// Base Medicare tax rate (employee share).
    static let medicareRate: Decimal = 0.0145
    /// Additional Medicare tax on wages above the threshold.
    static let additionalMedicareRate: Decimal = 0.009

    /// Additional-Medicare threshold per filing status.
    static func additionalMedicareThreshold(_ status: FilingStatus) -> Decimal {
        switch status {
        case .single, .headOfHousehold: return 200_000
        case .marriedJoint:             return 250_000
        case .marriedSeparate:          return 125_000
        }
    }
}
