import SwiftUI
import SwiftData

@Model
final class Unit {
    @Attribute(.unique) var id: UUID
    var label: String
    var bedrooms: Int
    var bathrooms: Double
    var sqft: Int
    var marketRent: Decimal
    var statusRaw: String
    var createdAt: Date

    var property: Property?

    @Relationship(deleteRule: .cascade, inverse: \Lease.unit)
    var leases: [Lease]

    init(
        id: UUID = UUID(),
        label: String,
        bedrooms: Int,
        bathrooms: Double,
        sqft: Int,
        marketRent: Decimal,
        status: UnitStatus = .vacant,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.sqft = sqft
        self.marketRent = marketRent
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.leases = []
    }

    var status: UnitStatus {
        get { UnitStatus(rawValue: statusRaw) ?? .vacant }
        set { statusRaw = newValue.rawValue }
    }

    var activeLease: Lease? {
        leases.first(where: { $0.isActive })
    }

    var bedBathSummary: String {
        let baths = bathrooms.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(bathrooms))
            : String(format: "%.1f", bathrooms)
        return "\(bedrooms) bd · \(baths) ba"
    }
}
