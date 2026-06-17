import Foundation

/// Short, friendly definitions for bonus words (a Pro perk in the Word Jar).
/// Falls back to a gentle generic line for words without a curated entry.
enum BonusDefinitions {
    private static let table: [String: String] = [
        "DEE": "the letter D",
        "APT": "well suited; likely",
        "PAN": "a shallow cooking dish",
        "TAN": "a light brown color",
        "RES": "informal for residence",
        "OES": "plural of the letter O",
        "NAE": "Scottish for no",
        "REZ": "informal for reservation",
        "BEZ": "a part of a deer's antler",
        "UTA": "a type of lizard",
        "NAM": "a Scrabble-valid term",
        "EMES": "plural of eme, an uncle",
        "BERMS": "raised banks or ledges",
        "BREE": "broth or thin soup",
        "BEEZ": "informal plural of bee"
    ]

    static func short(for word: String) -> String {
        table[word.uppercased()] ?? "A valid play in Tangle"
    }
}
