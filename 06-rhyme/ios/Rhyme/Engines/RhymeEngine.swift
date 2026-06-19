import Foundation

struct RhymeResult: Identifiable {
    let id = UUID()
    let word: String
    let syllables: Int
    let isPerfect: Bool
}

@Observable
class RhymeEngine {
    var searchText: String = ""
    var perfectRhymes: [RhymeResult] = []
    var nearRhymes: [RhymeResult] = []
    var syllableCount: Int = 0
    var isSearching: Bool = false

    func search(word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            perfectRhymes = []; nearRhymes = []; syllableCount = 0; return
        }
        isSearching = true
        let perfect = RhymeDatabase.perfectRhymes(for: trimmed)
            .map { RhymeResult(word: $0, syllables: RhymeDatabase.syllableCount(for: $0), isPerfect: true) }
            .sorted { $0.syllables < $1.syllables }
        let near = RhymeDatabase.nearRhymes(for: trimmed)
            .filter { w in !perfect.map(\.word).contains(w) }
            .map { RhymeResult(word: $0, syllables: RhymeDatabase.syllableCount(for: $0), isPerfect: false) }
            .sorted { $0.syllables < $1.syllables }
        perfectRhymes = perfect
        nearRhymes = near
        syllableCount = RhymeDatabase.syllableCount(for: trimmed)
        isSearching = false
    }

    func quickSuggest(for lineEndWord: String) -> [String] {
        let perfect = RhymeDatabase.perfectRhymes(for: lineEndWord)
        return Array(perfect.prefix(6))
    }
}
