import Foundation

/// A value describing a quiz to launch. Hashable so it can drive a
/// `navigationDestination`.
struct QuizConfig: Hashable, Identifiable {
    let id = UUID()
    let mode: QuizMode
    let continent: Continent?
    let length: Int
    let isDaily: Bool

    static func standard(mode: QuizMode, continent: Continent?, length: Int) -> QuizConfig {
        QuizConfig(mode: mode, continent: continent, length: length, isDaily: false)
    }

    static func daily() -> QuizConfig {
        // Mode/length are nominal for daily; the engine ignores them.
        QuizConfig(mode: .flagToCountry, continent: nil, length: 10, isDaily: true)
    }
}
