import SwiftUI
import SwiftData

enum ProductCategory: String, CaseIterable, Identifiable, Codable {
    case cleanser, toner, essence, serum, moisturizer, sunscreen
    case exfoliant, mask, eyeCream, faceOil, treatment, lipCare

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cleanser: return "Cleanser"
        case .toner: return "Toner"
        case .essence: return "Essence"
        case .serum: return "Serum"
        case .moisturizer: return "Moisturizer"
        case .sunscreen: return "Sunscreen"
        case .exfoliant: return "Exfoliant"
        case .mask: return "Mask"
        case .eyeCream: return "Eye cream"
        case .faceOil: return "Face oil"
        case .treatment: return "Treatment"
        case .lipCare: return "Lip care"
        }
    }

    var icon: String {
        switch self {
        case .cleanser: return "bubbles.and.sparkles"
        case .toner: return "drop"
        case .essence: return "drop.halffull"
        case .serum: return "eyedropper.halffull"
        case .moisturizer: return "cloud.fill"
        case .sunscreen: return "sun.max.fill"
        case .exfoliant: return "sparkles"
        case .mask: return "theatermasks.fill"
        case .eyeCream: return "eye.fill"
        case .faceOil: return "drop.fill"
        case .treatment: return "cross.vial.fill"
        case .lipCare: return "mouth.fill"
        }
    }

    var color: Color {
        switch self {
        case .cleanser: return Color(hex: 0x3E8F9E)
        case .toner: return Color(hex: 0x4E6BA8)
        case .essence: return Color(hex: 0x5E63A6)
        case .serum: return Color(hex: 0x9E7BA8)
        case .moisturizer: return Color(hex: 0x6E8FB0)
        case .sunscreen: return Color(hex: 0xC0A24E)
        case .exfoliant: return Color(hex: 0xC07AA0)
        case .mask: return Color(hex: 0x8B6FB0)
        case .eyeCream: return Color(hex: 0x3E9E78)
        case .faceOil: return Color(hex: 0xC08A3E)
        case .treatment: return Color(hex: 0xC0553E)
        case .lipCare: return Color(hex: 0xB07A8C)
        }
    }

    /// Default period-after-opening in months (industry rules of thumb).
    var defaultPAO: Int {
        switch self {
        case .sunscreen: return 12
        case .serum, .treatment, .exfoliant, .faceOil: return 6
        case .moisturizer, .cleanser, .toner, .essence, .eyeCream: return 12
        case .mask, .lipCare: return 12
        }
    }
}

@Model
final class Product {
    var name: String
    var brand: String
    var categoryRaw: String
    var openedDate: Date?
    var paoMonths: Int
    var price: Double
    var notes: String
    var isFinished: Bool
    var createdAt: Date

    @Relationship(inverse: \RoutineStep.product)
    var steps: [RoutineStep]

    init(name: String,
         brand: String = "",
         category: ProductCategory = .serum,
         openedDate: Date? = nil,
         paoMonths: Int = 12,
         price: Double = 0,
         notes: String = "") {
        self.name = name
        self.brand = brand
        self.categoryRaw = category.rawValue
        self.openedDate = openedDate
        self.paoMonths = max(1, paoMonths)
        self.price = max(0, price)
        self.notes = notes
        self.isFinished = false
        self.createdAt = .now
        self.steps = []
    }

    var category: ProductCategory {
        get { ProductCategory(rawValue: categoryRaw) ?? .serum }
        set { categoryRaw = newValue.rawValue }
    }

    var expiryDate: Date? {
        guard let openedDate else { return nil }
        return Calendar.current.date(byAdding: .month, value: paoMonths, to: openedDate)
    }
}
