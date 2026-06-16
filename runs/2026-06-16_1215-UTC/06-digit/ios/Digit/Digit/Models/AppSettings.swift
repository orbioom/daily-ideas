import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// How a child answers a question.
enum AnswerMode: String, CaseIterable, Identifiable {
    case numberPad = "Number Pad"
    case multipleChoice = "Multiple Choice"
    var id: String { rawValue }
    var symbol: String { self == .numberPad ? "square.grid.3x3.fill" : "rectangle.grid.1x2.fill" }
}

/// Number of questions in one practice round.
enum RoundLength: Int, CaseIterable, Identifiable {
    case short = 5, standard = 10, long = 15
    var id: Int { rawValue }
    var label: String { "\(rawValue) questions" }
}

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("soundEnabled") var soundEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("answerMode") var answerModeRaw = AnswerMode.numberPad.rawValue
    @AppStorage("roundLength") var roundLengthRaw = RoundLength.standard.rawValue
    @AppStorage("timerEnabled") var timerEnabled = false
    @AppStorage("isPro") var isPro = false

    /// The profile currently being practiced / inspected. Empty = none selected.
    @AppStorage("selectedProfileID") var selectedProfileID = ""

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var answerMode: AnswerMode {
        get { AnswerMode(rawValue: answerModeRaw) ?? .numberPad }
        set { answerModeRaw = newValue.rawValue }
    }

    var roundLength: RoundLength {
        get { RoundLength(rawValue: roundLengthRaw) ?? .standard }
        set { roundLengthRaw = newValue.rawValue }
    }
}
