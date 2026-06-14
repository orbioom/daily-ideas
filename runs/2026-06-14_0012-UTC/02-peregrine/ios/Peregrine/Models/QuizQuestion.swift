import Foundation

/// One generated question. Pure value type produced by `QuizEngine` and consumed
/// by the quiz player. `answerIndex` always points at the correct choice within
/// `choices`; the engine guarantees it is a valid index.
struct QuizQuestion: Identifiable, Hashable {
    let id = UUID()
    let mode: QuizMode
    /// The country this question is "about" (used for progress crediting and the
    /// follow-up fact). For population mode this is the more-populous country.
    let subjectISO2: String
    /// Prompt content. For flag modes this is the flag emoji; otherwise text.
    let promptPrimary: String
    /// Optional secondary prompt line (e.g. mode hint or the second country).
    let promptSecondary: String?
    /// Whether the primary prompt should render as a large flag glyph.
    let promptIsFlag: Bool
    let choices: [Choice]
    let answerIndex: Int

    struct Choice: Identifiable, Hashable {
        let id = UUID()
        /// Main label (country name, capital, continent, or country for pop mode).
        let label: String
        /// Optional flag glyph shown before the label (population mode).
        let flag: String?
    }

    var correctChoice: Choice? {
        guard choices.indices.contains(answerIndex) else { return nil }
        return choices[answerIndex]
    }

    /// A short reinforcing fact for the answer-feedback panel.
    func reinforcement(subject: Country) -> String {
        switch mode {
        case .flagToCountry:
            return "\(subject.flag) \(subject.name) — capital \(subject.capital)."
        case .countryToCapital:
            return "\(subject.capital) is the capital of \(subject.name)."
        case .capitalToCountry:
            return "\(subject.capital) is the capital of \(subject.name)."
        case .flagToContinent:
            return "\(subject.name) is in \(subject.continent.title)."
        case .biggerPopulation:
            return "\(subject.name) has about \(subject.populationText) people."
        }
    }
}
