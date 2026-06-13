import Foundation
import SwiftData

/// Backs the add / edit passage form. Validates input and persists changes.
@Observable
final class AddPassageViewModel {
    var title: String
    var source: String
    var category: PassageCategory
    var fullText: String

    /// When editing, the passage being modified; nil for a new passage.
    private let editing: Passage?

    init(editing: Passage? = nil, startingCategory: PassageCategory = .poem) {
        self.editing = editing
        self.title = editing?.title ?? ""
        self.source = editing?.source ?? ""
        self.category = editing?.category ?? startingCategory
        self.fullText = editing?.fullText ?? ""
    }

    var isEditing: Bool { editing != nil }

    var liveWordCount: Int { MaskEngine.wordCount(fullText) }

    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedText: String { fullText.trimmingCharacters(in: .whitespacesAndNewlines) }

    var canSave: Bool {
        !trimmedTitle.isEmpty && !trimmedText.isEmpty
    }

    /// Persist the new or edited passage. Returns false if validation fails.
    @discardableResult
    func save(context: ModelContext) -> Bool {
        guard canSave else { return false }
        let cleanTitle = trimmedTitle
        let cleanSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanText = fullText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editing {
            editing.title = cleanTitle
            editing.source = cleanSource
            editing.categoryRaw = category.rawValue
            editing.fullText = cleanText
        } else {
            let passage = Passage(title: cleanTitle,
                                  source: cleanSource,
                                  category: category,
                                  fullText: cleanText)
            context.insert(passage)
        }
        try? context.save()
        Haptics.success()
        return true
    }
}
