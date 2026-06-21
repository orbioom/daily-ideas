import Foundation
import Observation

@Observable
final class QuizEngine {
    let elements: [Element]
    var currentQuestion: QuizQuestion? = nil
    var score: Int = 0
    var questionsAnswered: Int = 0
    var correctCount: Int = 0
    var wrongCount: Int = 0
    var sessionHistory: [QuizAnswer] = []
    var quizMode: QuizMode = .symbolToName
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var selectedAnswer: String? = nil
    var showingResult: Bool = false

    enum QuizMode: String, CaseIterable, Codable {
        case symbolToName = "Symbol → Name"
        case nameToNumber = "Name → Number"
        case nameToCategory = "Name → Category"
        case nameToMass = "Name → Atomic Mass"

        var description: String { rawValue }
        var isPro: Bool { self == .nameToMass }

        var icon: String {
            switch self {
            case .symbolToName:  return "textformat.abc"
            case .nameToNumber:  return "number"
            case .nameToCategory: return "tag"
            case .nameToMass:    return "scalemass"
            }
        }
    }

    struct QuizQuestion: Identifiable {
        let id = UUID()
        let element: Element
        let options: [String]
        let correctAnswer: String
        let mode: QuizMode

        var prompt: String {
            switch mode {
            case .symbolToName:
                return element.symbol
            case .nameToNumber:
                return element.name
            case .nameToCategory:
                return element.name
            case .nameToMass:
                return element.name
            }
        }

        var questionText: String {
            switch mode {
            case .symbolToName:  return "What element has this symbol?"
            case .nameToNumber:  return "What is the atomic number?"
            case .nameToCategory: return "What category does this belong to?"
            case .nameToMass:    return "What is the approximate atomic mass?"
            }
        }
    }

    struct QuizAnswer {
        let element: Element
        let chosenAnswer: String
        let correctAnswer: String
        let wasCorrect: Bool
        let mode: QuizMode
        let timestamp: Date = Date()
    }

    init(elements: [Element] = Element.all) {
        self.elements = elements
    }

    func generateQuestion() {
        guard !elements.isEmpty else { return }
        let element = elements.randomElement()!
        let options: [String]
        let correct: String

        switch quizMode {
        case .symbolToName:
            correct = element.name
            var pool = elements.filter { $0.id != element.id }.shuffled().prefix(3).map { $0.name }
            pool.append(correct)
            options = pool.shuffled()

        case .nameToNumber:
            correct = "\(element.atomicNumber)"
            let nearby = nearbyNumbers(for: element.atomicNumber, total: elements.count)
            var pool = nearby.map { "\($0)" }
            if !pool.contains(correct) {
                pool = Array(pool.prefix(3))
                pool.append(correct)
            }
            options = pool.shuffled()

        case .nameToCategory:
            correct = element.category.rawValue
            var pool = ElementCategory.allCases.filter { $0 != element.category }.shuffled().prefix(3).map { $0.rawValue }
            pool.append(correct)
            options = pool.shuffled()

        case .nameToMass:
            correct = massRange(for: element.atomicMass)
            let fakes = fakeMassRanges(excluding: element.atomicMass)
            var pool = Array(fakes.prefix(3))
            pool.append(correct)
            options = pool.shuffled()
        }

        currentQuestion = QuizQuestion(
            element: element,
            options: options,
            correctAnswer: correct,
            mode: quizMode
        )
        selectedAnswer = nil
        showingResult = false
    }

    @discardableResult
    func answer(_ option: String) -> Bool {
        guard let question = currentQuestion else { return false }
        guard selectedAnswer == nil else { return false }

        selectedAnswer = option
        let isCorrect = option == question.correctAnswer
        questionsAnswered += 1

        if isCorrect {
            correctCount += 1
            score += 10
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
        } else {
            wrongCount += 1
            currentStreak = 0
        }

        let ans = QuizAnswer(
            element: question.element,
            chosenAnswer: option,
            correctAnswer: question.correctAnswer,
            wasCorrect: isCorrect,
            mode: quizMode
        )
        sessionHistory.append(ans)
        showingResult = true
        return isCorrect
    }

    func nextQuestion() {
        generateQuestion()
    }

    func reset() {
        score = 0
        questionsAnswered = 0
        correctCount = 0
        wrongCount = 0
        sessionHistory = []
        currentStreak = 0
        currentQuestion = nil
        selectedAnswer = nil
        showingResult = false
    }

    func resetStats() {
        reset()
        bestStreak = 0
    }

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctCount) / Double(questionsAnswered) * 100
    }

    var mostMissedElements: [Element] {
        var missCounts: [Int: Int] = [:]
        for ans in sessionHistory where !ans.wasCorrect {
            missCounts[ans.element.id, default: 0] += 1
        }
        return missCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .compactMap { Element.element(withNumber: $0.key) }
    }

    // MARK: - Private helpers

    private func nearbyNumbers(for num: Int, total: Int) -> [String] {
        var candidates = Set<Int>()
        let range = max(1, num - 10)...min(total, num + 10)
        while candidates.count < 3 {
            if let pick = range.randomElement(), pick != num {
                candidates.insert(pick)
            }
        }
        var result = candidates.map { "\($0)" }
        result.append("\(num)")
        return result
    }

    private func massRange(for mass: Double) -> String {
        let low = Int(mass / 10) * 10
        return "\(low)–\(low + 9)"
    }

    private func fakeMassRanges(excluding mass: Double) -> [String] {
        let correctLow = Int(mass / 10) * 10
        var fakes: [String] = []
        var tried = Set<Int>()
        tried.insert(correctLow)
        while fakes.count < 5 {
            let offset = Int.random(in: -5...5) * 10
            let candidate = correctLow + offset
            if candidate > 0 && !tried.contains(candidate) {
                tried.insert(candidate)
                fakes.append("\(candidate)–\(candidate + 9)")
            }
        }
        return fakes
    }
}
