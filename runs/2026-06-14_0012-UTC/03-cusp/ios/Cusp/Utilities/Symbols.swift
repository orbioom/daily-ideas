import Foundation

/// Curated palette of symbols (SF Symbols + a few emoji) for the symbol picker.
/// Grouped so the picker reads as an intentional, calm gallery.
enum SymbolLibrary {
    struct Group: Identifiable {
        let id = UUID()
        let name: String
        let symbols: [String]
    }

    static let groups: [Group] = [
        Group(name: "Celebration", symbols: [
            "gift.fill", "birthday.cake.fill", "party.popper.fill", "balloon.fill",
            "fireworks", "wineglass.fill", "heart.fill", "sparkles"
        ]),
        Group(name: "Time & Travel", symbols: [
            "hourglass", "calendar", "airplane", "beach.umbrella.fill",
            "sun.max.fill", "moon.stars.fill", "globe.americas.fill", "suitcase.fill"
        ]),
        Group(name: "Milestones", symbols: [
            "graduationcap.fill", "briefcase.fill", "house.fill", "figure.2",
            "trophy.fill", "flag.checkered", "star.fill", "crown.fill"
        ]),
        Group(name: "Everyday", symbols: [
            "cart.fill", "creditcard.fill", "book.fill", "dumbbell.fill",
            "leaf.fill", "pawprint.fill", "cup.and.saucer.fill", "music.note"
        ]),
        Group(name: "Emoji", symbols: [
            "🎂", "🎉", "💍", "🏖️", "🎓", "🎄", "✈️", "❤️",
            "🥳", "🌟", "🏆", "💼", "🎁", "🍾", "🌸", "💰"
        ])
    ]

    /// Flat list of all symbols (useful for validation / fallbacks).
    static var all: [String] { groups.flatMap { $0.symbols } }
}
