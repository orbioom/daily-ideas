import Foundation
import SwiftData

@Model
final class AtomPrefs {
    var colorBlindMode: Bool = false
    var temperatureUnitKelvin: Bool = false
    var defaultQuizMode: String = QuizEngine.QuizMode.symbolToName.rawValue
    var showAtomicMass: Bool = true
    var isPro: Bool = false

    init() {}

    var defaultQuizModeEnum: QuizEngine.QuizMode {
        get {
            QuizEngine.QuizMode(rawValue: defaultQuizMode) ?? .symbolToName
        }
        set {
            defaultQuizMode = newValue.rawValue
        }
    }
}
