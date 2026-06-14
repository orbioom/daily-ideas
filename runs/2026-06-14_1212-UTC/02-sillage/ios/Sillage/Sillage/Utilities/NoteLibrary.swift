import Foundation
import SwiftData

/// The seeded note library: ~55 real notes mapped to olfactory families.
/// Used by the note picker and by sample-data seeding.
enum NoteLibrary {
    /// (name, family) pairs. The names are unique within the library.
    static let entries: [(name: String, family: NoteFamily)] = [
        // Citrus
        ("Bergamot", .citrus), ("Lemon", .citrus), ("Grapefruit", .citrus),
        ("Mandarin", .citrus), ("Bitter Orange", .citrus), ("Yuzu", .citrus),
        // Floral
        ("Rose", .floral), ("Jasmine", .floral), ("Tuberose", .floral),
        ("Iris", .floral), ("Ylang-Ylang", .floral), ("Orange Blossom", .floral),
        ("Violet", .floral), ("Lavender", .floral), ("Geranium", .floral),
        // Woody
        ("Sandalwood", .woody), ("Cedar", .woody), ("Vetiver", .woody),
        ("Oud", .woody), ("Guaiac Wood", .woody), ("Patchouli", .woody),
        // Amber / oriental
        ("Ambroxan", .amber), ("Amber", .amber), ("Labdanum", .amber),
        ("Benzoin", .amber), ("Frankincense", .amber), ("Myrrh", .amber),
        // Fresh
        ("Mint", .fresh), ("Green Tea", .fresh), ("Petitgrain", .fresh),
        ("Aldehydes", .fresh), ("Ozonic Accord", .fresh),
        // Gourmand
        ("Vanilla", .gourmand), ("Tonka Bean", .gourmand), ("Caramel", .gourmand),
        ("Cocoa", .gourmand), ("Coffee", .gourmand), ("Honey", .gourmand),
        ("Praline", .gourmand),
        // Spicy
        ("Black Pepper", .spicy), ("Pink Pepper", .spicy), ("Cardamom", .spicy),
        ("Cinnamon", .spicy), ("Saffron", .spicy), ("Nutmeg", .spicy),
        // Green
        ("Galbanum", .green), ("Fig Leaf", .green), ("Basil", .green),
        ("Tomato Leaf", .green),
        // Fougère
        ("Oakmoss", .fougere), ("Coumarin", .fougere),
        // Chypre
        ("Bergamot-Oakmoss Accord", .chypre), ("Labdanum-Patchouli Accord", .chypre),
        // Aquatic
        ("Sea Salt", .aquatic), ("Calone", .aquatic), ("Seaweed", .aquatic),
        // Leather
        ("Leather", .leather), ("Suede", .leather), ("Birch Tar", .leather),
        // Musk
        ("White Musk", .musk), ("Ambrette", .musk), ("Civet Accord", .musk)
    ]

    /// Ensure all library notes exist in the store. Returns a name→note map for all current notes.
    @discardableResult
    static func ensureSeeded(context: ModelContext) -> [String: ScentNote] {
        var existing = fetchAll(context: context)
        for entry in entries where existing[entry.name] == nil {
            let note = ScentNote(name: entry.name, family: entry.family, isSeeded: true)
            context.insert(note)
            existing[entry.name] = note
        }
        return existing
    }

    /// All notes currently in the store, keyed by name.
    static func fetchAll(context: ModelContext) -> [String: ScentNote] {
        let descriptor = FetchDescriptor<ScentNote>()
        let notes = (try? context.fetch(descriptor)) ?? []
        var map: [String: ScentNote] = [:]
        for n in notes { map[n.name] = n }
        return map
    }
}
