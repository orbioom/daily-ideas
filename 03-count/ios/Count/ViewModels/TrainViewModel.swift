import SwiftUI
import SwiftData

@Observable final class TrainViewModel {
    var scenario: HandScenario = BasicStrategy.randomScenario()
    var lastResult: BJAction? = nil
    var lastWasCorrect: Bool = false
    var showResult: Bool = false
    var sessionCorrect: Int = 0
    var sessionTotal: Int = 0
    var sessionId: String = UUID().uuidString
    var difficulty: String = "Standard"

    func choose(_ action: BJAction, context: ModelContext, showCorrectOnWrong: Bool, haptic: Bool) {
        let correct = BasicStrategy.correctAction(for: scenario)
        let isCorrect = action == correct
        lastResult = correct
        lastWasCorrect = isCorrect
        showResult = true
        sessionTotal += 1
        if isCorrect { sessionCorrect += 1 }
        if haptic {
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(isCorrect ? .success : .error)
        }
        let record = TrainingRecord(
            scenario: scenario.displayString,
            correctAction: correct.rawValue,
            chosenAction: action.rawValue,
            isCorrect: isCorrect,
            difficulty: difficulty,
            sessionId: sessionId
        )
        context.insert(record)
        try? context.save()
    }

    func next() {
        scenario = BasicStrategy.randomScenario()
        showResult = false
        lastResult = nil
    }

    func resetSession() {
        sessionCorrect = 0
        sessionTotal = 0
        sessionId = UUID().uuidString
        scenario = BasicStrategy.randomScenario()
        showResult = false
    }

    var accuracy: Double {
        sessionTotal == 0 ? 0 : Double(sessionCorrect) / Double(sessionTotal)
    }
}
