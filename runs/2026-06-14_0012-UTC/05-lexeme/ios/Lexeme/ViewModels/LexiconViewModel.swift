import Foundation

/// Filters and searches the bundled word bank for the Lexicon screen.
@MainActor
@Observable
final class LexiconViewModel {
    var query = ""
    var tierFilter: WordTier? = nil
    var posFilter: PartOfSpeech? = nil
    var tagFilter: String? = nil
    /// "all" / "learned" / "favorite" / "review"
    var statusFilter: StatusFilter = .all

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all, learned, favorite, review
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "All"
            case .learned: return "Learned"
            case .favorite: return "Favorites"
            case .review: return "In review"
            }
        }
    }

    var hasActiveFilter: Bool {
        tierFilter != nil || posFilter != nil || tagFilter != nil || statusFilter != .all || !query.isEmpty
    }

    func clear() {
        query = ""; tierFilter = nil; posFilter = nil; tagFilter = nil; statusFilter = .all
    }

    /// Applies all filters against the bank, using the supplied progress lookup.
    func results(progressByID: [String: WordProgress]) -> [VocabWord] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return WordBank.all.filter { w in
            if let tier = tierFilter, w.tier != tier { return false }
            if let pos = posFilter, w.partOfSpeech != pos { return false }
            if let tag = tagFilter, !w.tags.contains(tag) { return false }
            switch statusFilter {
            case .all: break
            case .learned:  if progressByID[w.id]?.learned != true { return false }
            case .favorite: if progressByID[w.id]?.favorite != true { return false }
            case .review:
                guard let p = progressByID[w.id] else { return false }
                if p.learned { return false }
                if p.seen == 0 && p.nextReview == .distantPast { return false }
            }
            if !q.isEmpty {
                let inWord = w.word.lowercased().contains(q)
                let inDef = w.definition.lowercased().contains(q)
                let inSyn = w.synonyms.contains { $0.lowercased().contains(q) }
                if !(inWord || inDef || inSyn) { return false }
            }
            return true
        }
        .sorted { $0.word.lowercased() < $1.word.lowercased() }
    }
}
