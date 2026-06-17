import Foundation

/// A catalog verb. Static data, NOT persisted in SwiftData.
struct Verb: Identifiable, Hashable {
    let infinitive: String       // e.g. "hablar", "être"
    let language: Language
    let meaning: String          // English meaning, e.g. "to speak"
    let group: VerbGroup
    let isIrregular: Bool
    /// Whether this verb's compound tenses use "être" as auxiliary (French only).
    let usesEtre: Bool

    var id: String { "\(language.rawValue)-\(infinitive)" }

    init(_ infinitive: String,
         _ language: Language,
         _ meaning: String,
         _ group: VerbGroup,
         irregular: Bool = false,
         usesEtre: Bool = false) {
        self.infinitive = infinitive
        self.language = language
        self.meaning = meaning
        self.group = group
        self.isIrregular = irregular
        self.usesEtre = usesEtre
    }

    /// The stem (infinitive minus the 2-char ending). Guarded for safety.
    var stem: String {
        guard infinitive.count >= 2 else { return infinitive }
        return String(infinitive.dropLast(2))
    }

    /// The 2-character ending, lowercased.
    var ending: String {
        guard infinitive.count >= 2 else { return infinitive }
        return String(infinitive.suffix(2)).lowercased()
    }
}
