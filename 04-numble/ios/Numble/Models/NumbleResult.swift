import Foundation
import SwiftData

@Model
final class NumbleResult {
    var id: UUID = UUID()
    var date: Date = Date()
    var equation: String = ""
    var solved: Bool = false
    var attemptsUsed: Int = 0
    var maxAttempts: Int = 6

    init(equation: String, solved: Bool, attemptsUsed: Int, maxAttempts: Int) {
        self.equation = equation
        self.solved = solved
        self.attemptsUsed = attemptsUsed
        self.maxAttempts = maxAttempts
    }
}
