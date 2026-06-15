import Foundation
import SwiftData

/// A stored loyalty / membership card. Holds the scannable value plus presentation
/// metadata. The barcode itself is rendered on-device from `codeValue` + `format`.
@Model
final class LoyaltyCard {
    @Attribute(.unique) var id: UUID
    var name: String
    var storeName: String
    var codeValue: String
    var formatRaw: String
    var categoryRaw: String
    var colorHex: String
    var notes: String
    var isFavorite: Bool
    var createdAt: Date
    var lastUsedAt: Date?

    init(id: UUID = UUID(),
         name: String,
         storeName: String,
         codeValue: String,
         format: BarcodeFormat,
         category: CardCategory,
         colorHex: String,
         notes: String = "",
         isFavorite: Bool = false,
         createdAt: Date = Date(),
         lastUsedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.storeName = storeName
        self.codeValue = codeValue
        self.formatRaw = format.rawValue
        self.categoryRaw = category.rawValue
        self.colorHex = colorHex
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    /// Decoded format, defaulting to Code 128 if a stored raw value is ever unknown.
    var format: BarcodeFormat {
        get { BarcodeFormat(rawValue: formatRaw) ?? .code128 }
        set { formatRaw = newValue.rawValue }
    }

    /// Decoded category, defaulting to `.other` for unknown raw values.
    var category: CardCategory {
        get { CardCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// A non-empty title for display, preferring the card name then store name.
    var displayTitle: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let store = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.isEmpty ? "Card" : store
    }
}
