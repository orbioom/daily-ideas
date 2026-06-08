import Foundation
import SwiftData

/// A label/category for focus sessions ("Study", "Work").
@Model
final class FocusTag {
    var id: UUID
    var name: String
    var symbol: String
    var colorHex: UInt32
    var order: Int

    init(id: UUID = UUID(), name: String, symbol: String, colorHex: UInt32, order: Int = 0) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.order = order
    }

    static func ensureDefaults(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<FocusTag>())) ?? 0
        guard existing == 0 else { return }
        let seeds: [(String, String, UInt32)] = [
            ("Study", "book.fill", 0x4E6BA8),
            ("Work", "laptopcomputer", 0x3E7E5A),
            ("Read", "books.vertical.fill", 0xB5552F),
            ("Create", "paintbrush.fill", 0x7A5EA8),
            ("Deep work", "brain.head.profile", 0x2C8C7C),
        ]
        for (i, s) in seeds.enumerated() {
            context.insert(FocusTag(name: s.0, symbol: s.1, colorHex: s.2, order: i))
        }
        try? context.save()
    }
}
