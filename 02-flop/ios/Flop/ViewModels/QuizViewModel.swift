import Foundation
import Observation
import SwiftUI

@Observable
final class QuizViewModel {
    var currentHand: HandQuiz = PokerEngine.randomQuiz()
    var selectedAction: PreFlopAction?
    var showResult = false
    var isCorrect = false
    var sessionCorrect = 0
    var sessionTotal = 0
    var streak = 0
    var bestStreak = 0
    var isAnimating = false

    func answer(_ action: PreFlopAction) {
        guard !showResult else { return }
        selectedAction = action
        isCorrect = action == currentHand.correctAction
        showResult = true
        sessionTotal += 1
        if isCorrect {
            sessionCorrect += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            streak = 0
        }
    }

    func nextHand() {
        currentHand = PokerEngine.randomQuiz()
        selectedAction = nil
        showResult = false
        isCorrect = false
    }

    var accuracy: Double {
        guard sessionTotal > 0 else { return 0 }
        return Double(sessionCorrect) / Double(sessionTotal) * 100
    }

    var actionColor: Color {
        guard let action = selectedAction else { return .clear }
        if action == currentHand.correctAction { return FlopTheme.correctGreen }
        return FlopTheme.wrongRed
    }
}
