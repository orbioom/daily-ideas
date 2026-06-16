import Foundation

/// A single multiple-choice question. Pure value type; content lives in QuestionBank.
struct Question: Identifiable, Hashable {
    let id: Int
    let category: QuestionCategory
    let text: String
    let options: [String]          // exactly 4
    let correctIndex: Int          // 0...3
    let explanation: String        // 1–2 factual, general sentences
    let isSignQuestion: Bool
    /// For sign questions, the name of the related sign in SignLibrary.
    let relatedSign: String?

    init(
        id: Int,
        category: QuestionCategory,
        text: String,
        options: [String],
        correctIndex: Int,
        explanation: String,
        isSignQuestion: Bool = false,
        relatedSign: String? = nil
    ) {
        self.id = id
        self.category = category
        self.text = text
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.isSignQuestion = isSignQuestion
        self.relatedSign = relatedSign
    }

    /// Safe accessor for an option; returns empty string for out-of-range indexes.
    func option(at index: Int) -> String {
        guard options.indices.contains(index) else { return "" }
        return options[index]
    }

    var correctOption: String { option(at: correctIndex) }

    /// Letter label (A, B, C, D) for an option index.
    static func letter(_ index: Int) -> String {
        let letters = ["A", "B", "C", "D"]
        guard letters.indices.contains(index) else { return "" }
        return letters[index]
    }
}
