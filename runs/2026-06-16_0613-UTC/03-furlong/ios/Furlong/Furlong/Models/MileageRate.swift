import Foundation
import SwiftData

/// IRS standard mileage rates (dollars per mile) for a given tax year.
@Model
final class MileageRate {
    @Attribute(.unique) var year: Int
    var businessRate: Decimal
    var medicalRate: Decimal
    var charityRate: Decimal

    init(year: Int, businessRate: Decimal, medicalRate: Decimal, charityRate: Decimal) {
        self.year = year
        self.businessRate = businessRate
        self.medicalRate = medicalRate
        self.charityRate = charityRate
    }

    func rate(for purpose: TripPurpose) -> Decimal {
        switch purpose {
        case .business: return businessRate
        case .medical: return medicalRate
        case .charity: return charityRate
        case .personal: return 0
        }
    }

    /// Real IRS standard mileage rates, 2022–2026. Charity is statutory (0.14).
    /// 2022 used a mid-year split; we seed the second-half (higher) figures.
    static let seed: [MileageRate] = [
        MileageRate(year: 2022, businessRate: 0.625, medicalRate: 0.22, charityRate: 0.14),
        MileageRate(year: 2023, businessRate: 0.655, medicalRate: 0.22, charityRate: 0.14),
        MileageRate(year: 2024, businessRate: 0.67, medicalRate: 0.21, charityRate: 0.14),
        MileageRate(year: 2025, businessRate: 0.70, medicalRate: 0.21, charityRate: 0.14),
        MileageRate(year: 2026, businessRate: 0.70, medicalRate: 0.21, charityRate: 0.14)
    ]
}
