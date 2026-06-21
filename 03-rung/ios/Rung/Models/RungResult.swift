import Foundation
import SwiftData

@Model
final class RungResult {
    var id: UUID = UUID()
    var date: Date = Date()
    var mode: String = "daily"        // "daily" or "practice"
    var startWord: String = ""
    var targetWord: String = ""
    var steps: Int = 0
    var parSteps: Int = 0
    var solved: Bool = false
    var durationSeconds: Int = 0

    init(mode: String, startWord: String, targetWord: String,
         steps: Int, parSteps: Int, solved: Bool, durationSeconds: Int) {
        self.mode = mode
        self.startWord = startWord
        self.targetWord = targetWord
        self.steps = steps
        self.parSteps = parSteps
        self.solved = solved
        self.durationSeconds = durationSeconds
    }
}
