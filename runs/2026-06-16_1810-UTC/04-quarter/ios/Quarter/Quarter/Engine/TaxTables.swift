import Foundation

/// A single marginal bracket: applies `rate` to taxable income above `lowerBound`
/// up to `upperBound` (nil means "and above").
struct TaxBracket {
    let lowerBound: Decimal
    let upperBound: Decimal?   // exclusive upper edge; nil = infinity
    let rate: Decimal          // e.g. 0.22
}

/// Embedded federal figures for a single tax year.
struct TaxYearData {
    let year: Int
    let standardDeduction: [FilingStatus: Decimal]
    let brackets: [FilingStatus: [TaxBracket]]
    let socialSecurityWageBase: Decimal

    func standardDeduction(for status: FilingStatus) -> Decimal {
        standardDeduction[status] ?? 0
    }

    func brackets(for status: FilingStatus) -> [TaxBracket] {
        brackets[status] ?? []
    }
}

/// Static published federal figures for tax years 2024 and 2025.
///
/// Sources:
///  - 2024: IRS Rev. Proc. 2023-34.
///  - 2025 brackets: IRS Rev. Proc. 2024-40.
///  - 2025 standard deduction: amended by the One Big Beautiful Bill Act (2025)
///    to $15,750 single / $31,500 MFJ / $15,750 MFS / $23,625 HoH.
///  - Social Security wage base: SSA (2024 = $168,600, 2025 = $176,100).
enum TaxTables {

    static let supportedYears: [Int] = [2024, 2025]

    static func data(for year: Int) -> TaxYearData {
        switch year {
        case 2025: return y2025
        default:   return y2024   // 2024 is the safe fallback
        }
    }

    // MARK: - 2024

    static let y2024 = TaxYearData(
        year: 2024,
        standardDeduction: [
            .single: 14_600,
            .marriedFilingJointly: 29_200,
            .marriedFilingSeparately: 14_600,
            .headOfHousehold: 21_900
        ],
        brackets: [
            .single: [
                TaxBracket(lowerBound: 0,        upperBound: 11_600,  rate: 0.10),
                TaxBracket(lowerBound: 11_600,   upperBound: 47_150,  rate: 0.12),
                TaxBracket(lowerBound: 47_150,   upperBound: 100_525, rate: 0.22),
                TaxBracket(lowerBound: 100_525,  upperBound: 191_950, rate: 0.24),
                TaxBracket(lowerBound: 191_950,  upperBound: 243_725, rate: 0.32),
                TaxBracket(lowerBound: 243_725,  upperBound: 609_350, rate: 0.35),
                TaxBracket(lowerBound: 609_350,  upperBound: nil,     rate: 0.37)
            ],
            .marriedFilingJointly: [
                TaxBracket(lowerBound: 0,        upperBound: 23_200,  rate: 0.10),
                TaxBracket(lowerBound: 23_200,   upperBound: 94_300,  rate: 0.12),
                TaxBracket(lowerBound: 94_300,   upperBound: 201_050, rate: 0.22),
                TaxBracket(lowerBound: 201_050,  upperBound: 383_900, rate: 0.24),
                TaxBracket(lowerBound: 383_900,  upperBound: 487_450, rate: 0.32),
                TaxBracket(lowerBound: 487_450,  upperBound: 731_200, rate: 0.35),
                TaxBracket(lowerBound: 731_200,  upperBound: nil,     rate: 0.37)
            ],
            .marriedFilingSeparately: [
                TaxBracket(lowerBound: 0,        upperBound: 11_600,  rate: 0.10),
                TaxBracket(lowerBound: 11_600,   upperBound: 47_150,  rate: 0.12),
                TaxBracket(lowerBound: 47_150,   upperBound: 100_525, rate: 0.22),
                TaxBracket(lowerBound: 100_525,  upperBound: 191_950, rate: 0.24),
                TaxBracket(lowerBound: 191_950,  upperBound: 243_725, rate: 0.32),
                TaxBracket(lowerBound: 243_725,  upperBound: 365_600, rate: 0.35),
                TaxBracket(lowerBound: 365_600,  upperBound: nil,     rate: 0.37)
            ],
            .headOfHousehold: [
                TaxBracket(lowerBound: 0,        upperBound: 16_550,  rate: 0.10),
                TaxBracket(lowerBound: 16_550,   upperBound: 63_100,  rate: 0.12),
                TaxBracket(lowerBound: 63_100,   upperBound: 100_500, rate: 0.22),
                TaxBracket(lowerBound: 100_500,  upperBound: 191_950, rate: 0.24),
                TaxBracket(lowerBound: 191_950,  upperBound: 243_700, rate: 0.32),
                TaxBracket(lowerBound: 243_700,  upperBound: 609_350, rate: 0.35),
                TaxBracket(lowerBound: 609_350,  upperBound: nil,     rate: 0.37)
            ]
        ],
        socialSecurityWageBase: 168_600
    )

    // MARK: - 2025

    static let y2025 = TaxYearData(
        year: 2025,
        standardDeduction: [
            .single: 15_750,
            .marriedFilingJointly: 31_500,
            .marriedFilingSeparately: 15_750,
            .headOfHousehold: 23_625
        ],
        brackets: [
            .single: [
                TaxBracket(lowerBound: 0,        upperBound: 11_925,  rate: 0.10),
                TaxBracket(lowerBound: 11_925,   upperBound: 48_475,  rate: 0.12),
                TaxBracket(lowerBound: 48_475,   upperBound: 103_350, rate: 0.22),
                TaxBracket(lowerBound: 103_350,  upperBound: 197_300, rate: 0.24),
                TaxBracket(lowerBound: 197_300,  upperBound: 250_525, rate: 0.32),
                TaxBracket(lowerBound: 250_525,  upperBound: 626_350, rate: 0.35),
                TaxBracket(lowerBound: 626_350,  upperBound: nil,     rate: 0.37)
            ],
            .marriedFilingJointly: [
                TaxBracket(lowerBound: 0,        upperBound: 23_850,  rate: 0.10),
                TaxBracket(lowerBound: 23_850,   upperBound: 96_950,  rate: 0.12),
                TaxBracket(lowerBound: 96_950,   upperBound: 206_700, rate: 0.22),
                TaxBracket(lowerBound: 206_700,  upperBound: 394_600, rate: 0.24),
                TaxBracket(lowerBound: 394_600,  upperBound: 501_050, rate: 0.32),
                TaxBracket(lowerBound: 501_050,  upperBound: 751_600, rate: 0.35),
                TaxBracket(lowerBound: 751_600,  upperBound: nil,     rate: 0.37)
            ],
            .marriedFilingSeparately: [
                TaxBracket(lowerBound: 0,        upperBound: 11_925,  rate: 0.10),
                TaxBracket(lowerBound: 11_925,   upperBound: 48_475,  rate: 0.12),
                TaxBracket(lowerBound: 48_475,   upperBound: 103_350, rate: 0.22),
                TaxBracket(lowerBound: 103_350,  upperBound: 197_300, rate: 0.24),
                TaxBracket(lowerBound: 197_300,  upperBound: 250_525, rate: 0.32),
                TaxBracket(lowerBound: 250_525,  upperBound: 375_800, rate: 0.35),
                TaxBracket(lowerBound: 375_800,  upperBound: nil,     rate: 0.37)
            ],
            .headOfHousehold: [
                TaxBracket(lowerBound: 0,        upperBound: 17_000,  rate: 0.10),
                TaxBracket(lowerBound: 17_000,   upperBound: 64_850,  rate: 0.12),
                TaxBracket(lowerBound: 64_850,   upperBound: 103_350, rate: 0.22),
                TaxBracket(lowerBound: 103_350,  upperBound: 197_300, rate: 0.24),
                TaxBracket(lowerBound: 197_300,  upperBound: 250_500, rate: 0.32),
                TaxBracket(lowerBound: 250_500,  upperBound: 626_350, rate: 0.35),
                TaxBracket(lowerBound: 626_350,  upperBound: nil,     rate: 0.37)
            ]
        ],
        socialSecurityWageBase: 176_100
    )
}
