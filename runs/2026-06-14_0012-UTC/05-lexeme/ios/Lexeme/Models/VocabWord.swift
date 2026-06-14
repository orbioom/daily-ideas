import SwiftUI

/// Part of speech for a vocabulary word.
enum PartOfSpeech: String, CaseIterable, Identifiable, Codable {
    case noun, verb, adjective, adverb
    var id: String { rawValue }

    var label: String {
        switch self {
        case .noun: return "noun"
        case .verb: return "verb"
        case .adjective: return "adjective"
        case .adverb: return "adverb"
        }
    }
    /// Compact abbreviation used in chips.
    var abbrev: String {
        switch self {
        case .noun: return "n."
        case .verb: return "v."
        case .adjective: return "adj."
        case .adverb: return "adv."
        }
    }
}

/// Difficulty / curriculum tier.
enum WordTier: String, CaseIterable, Identifiable, Codable {
    case everyday, sat, gre
    var id: String { rawValue }

    var label: String {
        switch self {
        case .everyday: return "Everyday"
        case .sat: return "SAT"
        case .gre: return "GRE"
        }
    }
    /// Sort weight (everyday easiest).
    var rank: Int {
        switch self {
        case .everyday: return 0
        case .sat: return 1
        case .gre: return 2
        }
    }
    /// Whether this tier requires Lexeme Pro.
    var requiresPro: Bool { self != .everyday }
}

/// An immutable curated dictionary entry. Lives in `WordBank` (bundled), not SwiftData.
struct VocabWord: Identifiable, Hashable {
    /// Lowercased word, unique — also the stable `wordID` used by SwiftData progress.
    let id: String
    let word: String
    let partOfSpeech: PartOfSpeech
    let definition: String
    /// A sentence that USES the word (so it can be blanked for fill-in-the-blank).
    let example: String
    let synonyms: [String]
    let antonyms: [String]
    let etymology: String
    let tierRaw: String
    let tags: [String]

    var tier: WordTier { WordTier(rawValue: tierRaw) ?? .everyday }

    init(_ word: String,
         _ partOfSpeech: PartOfSpeech,
         _ definition: String,
         _ example: String,
         synonyms: [String] = [],
         antonyms: [String] = [],
         etymology: String,
         tier: WordTier,
         tags: [String] = []) {
        self.id = word.lowercased()
        self.word = word
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.example = example
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.etymology = etymology
        self.tierRaw = tier.rawValue
        self.tags = tags
    }
}
