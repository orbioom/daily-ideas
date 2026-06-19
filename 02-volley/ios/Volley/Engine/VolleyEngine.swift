import Foundation

@Observable
final class VolleyEngine {
    var currentQuestions: [Question] = []
    var currentIndex: Int = 0
    var sessionAnswered: Int = 0
    var sessionSkipped: Int = 0
    var isComplete: Bool = false

    var currentQuestion: Question? {
        guard currentIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentIndex]
    }

    func loadQuestions(
        _ allQuestions: [Question],
        mode: QuestionMode?,
        category: QuestionCategory?,
        safeMode: Bool,
        limit: Int
    ) {
        var filtered = allQuestions.filter { $0.isEnabled }

        if let m = mode {
            filtered = filtered.filter { $0.mode == m.rawValue }
        }

        if let c = category, c != .all {
            filtered = filtered.filter { $0.category == c.rawValue }
        }

        if safeMode {
            filtered = filtered.filter { $0.category != QuestionCategory.party.rawValue }
        }

        filtered = Array(filtered.shuffled().prefix(limit))
        currentQuestions = filtered
        currentIndex = 0
        sessionAnswered = 0
        sessionSkipped = 0
        isComplete = false
    }

    func next() {
        sessionAnswered += 1
        advance()
    }

    func skip() {
        sessionSkipped += 1
        advance()
    }

    private func advance() {
        let nextIndex = currentIndex + 1
        if nextIndex >= currentQuestions.count {
            isComplete = true
        } else {
            currentIndex = nextIndex
        }
    }

    var progress: Double {
        guard !currentQuestions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(currentQuestions.count)
    }

    var progressDisplay: String {
        "\(currentIndex + 1) / \(currentQuestions.count)"
    }
}
