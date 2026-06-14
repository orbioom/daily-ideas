import Foundation

/// Central rules for the honest free/Pro split. Free tier unlocks three
/// continents; Pro unlocks all six (plus all modes and unlimited quizzes,
/// enforced elsewhere). Keeping the rule here avoids drift across screens.
enum ProAccess {
    /// Continents available without Pro.
    static let freeContinents: [Continent] = [.europe, .africa, .asia]

    static func continentUnlocked(_ continent: Continent, isPro: Bool) -> Bool {
        isPro || freeContinents.contains(continent)
    }
}
