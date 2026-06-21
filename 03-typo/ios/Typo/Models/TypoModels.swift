import Foundation
import SwiftData

enum TypingMode: String, CaseIterable, Codable {
    case words = "Words"
    case sentences = "Sentences"
    case code = "Code"
    case numbers = "Numbers"
}

enum TestDuration: Int, CaseIterable, Codable {
    case fifteen = 15
    case thirty = 30
    case sixty = 60
    case onetwenty = 120

    var label: String {
        switch self {
        case .fifteen: return "15s"
        case .thirty: return "30s"
        case .sixty: return "60s"
        case .onetwenty: return "2m"
        }
    }
}

enum WordCount: Int, CaseIterable, Codable {
    case ten = 10
    case twenty = 20
    case fifty = 50
    case hundred = 100

    var label: String { "\(rawValue) words" }
}

@Model
final class TypoResult {
    var date: Date
    var wpm: Double
    var accuracy: Double
    var rawWpm: Double
    var mode: String
    var duration: Int
    var wordCount: Int
    var correctChars: Int
    var totalChars: Int

    init(date: Date = .now, wpm: Double, accuracy: Double, rawWpm: Double,
         mode: String, duration: Int, wordCount: Int, correctChars: Int, totalChars: Int) {
        self.date = date
        self.wpm = wpm
        self.accuracy = accuracy
        self.rawWpm = rawWpm
        self.mode = mode
        self.duration = duration
        self.wordCount = wordCount
        self.correctChars = correctChars
        self.totalChars = totalChars
    }
}

@Model
final class TypoSettings {
    var hasCompletedOnboarding: Bool
    var selectedMode: String
    var testDuration: Int
    var wordCountMode: Int
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var showLiveWpm: Bool
    var showKeyboard: Bool
    var isPro: Bool
    var caretStyle: String

    init() {
        self.hasCompletedOnboarding = false
        self.selectedMode = TypingMode.words.rawValue
        self.testDuration = TestDuration.sixty.rawValue
        self.wordCountMode = WordCount.twenty.rawValue
        self.soundEnabled = false
        self.hapticsEnabled = true
        self.showLiveWpm = true
        self.showKeyboard = true
        self.isPro = false
        self.caretStyle = "line"
    }
}

struct TypingContent {
    static let commonWords = [
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "it",
        "for", "not", "on", "with", "he", "as", "you", "do", "at", "this",
        "but", "his", "by", "from", "they", "we", "say", "her", "she", "or",
        "an", "will", "my", "one", "all", "would", "there", "their", "what",
        "so", "up", "out", "if", "about", "who", "get", "which", "go", "me",
        "when", "make", "can", "like", "time", "no", "just", "him", "know",
        "take", "people", "into", "year", "your", "good", "some", "could",
        "them", "see", "other", "than", "then", "now", "look", "only", "come",
        "its", "over", "think", "also", "back", "after", "use", "two", "how",
        "our", "work", "first", "well", "way", "even", "new", "want", "because",
        "any", "these", "give", "day", "most", "us", "great", "between", "need",
        "large", "often", "hand", "high", "place", "hold", "turn", "ask",
        "show", "move", "live", "same", "change", "try", "tell", "very",
        "much", "still", "own", "around", "every", "name", "off", "those",
        "help", "world", "again", "each", "play", "long", "left", "part",
        "small", "number", "old", "right", "big", "real", "life", "few",
        "north", "open", "seem", "together", "next", "white", "late", "point",
        "let", "city", "earth", "start", "close", "last", "come", "grow"
    ]

    static let sentences = [
        "The quick brown fox jumps over the lazy dog.",
        "Pack my box with five dozen liquor jugs.",
        "How razorback-jumping frogs can level six piqued gymnasts.",
        "Sphinx of black quartz, judge my vow.",
        "Two driven jocks help fax my big quiz.",
        "The five boxing wizards jump quickly.",
        "Practice makes perfect, so keep typing every day.",
        "Speed comes from accuracy, not the other way around.",
        "A good typist focuses on rhythm and consistency.",
        "Touch typing allows you to type without looking at the keys.",
        "The keyboard layout was designed to slow typists down.",
        "Improving your typing speed can save hours every week.",
        "Keep your fingers on the home row for maximum efficiency.",
        "Regular practice sessions of fifteen minutes help build speed.",
        "Accuracy matters more than raw speed in professional settings.",
        "Try to maintain a steady pace rather than bursting and pausing.",
        "Learning proper finger placement is essential for fast typing.",
    ]

    static let codeSnippets = [
        "let result = array.filter { $0 > 0 }.map { $0 * 2 }",
        "func greet(name: String) -> String { return \"Hello, \\(name)!\" }",
        "struct Point { var x: Double; var y: Double }",
        "for i in 0..<10 { print(i * i) }",
        "guard let value = optional else { return nil }",
        "let sorted = items.sorted { $0.date < $1.date }",
        "class ViewModel: ObservableObject { @Published var count = 0 }",
        "if condition { doSomething() } else { doOther() }",
        "let sum = numbers.reduce(0, +)",
        "Task { await loadData() }",
    ]

    static let numberSets = [
        "1 2 3 4 5 6 7 8 9 0",
        "42 17 99 3 56 81 24 7 13 88",
        "3.14 2.71 1.41 1.73 0.57",
        "100 200 300 400 500 600 700 800 900",
        "12345 67890 11111 22222 33333",
    ]

    static func generate(mode: TypingMode, count: Int) -> String {
        switch mode {
        case .words:
            return (0..<count).map { _ in commonWords.randomElement()! }.joined(separator: " ")
        case .sentences:
            var result = ""
            while result.split(separator: " ").count < count {
                result += (result.isEmpty ? "" : " ") + sentences.randomElement()!
            }
            return result
        case .code:
            return codeSnippets.shuffled().prefix(max(1, count / 8)).joined(separator: "\n")
        case .numbers:
            return (0..<max(1, count / 10)).map { _ in numberSets.randomElement()! }.joined(separator: " ")
        }
    }
}
