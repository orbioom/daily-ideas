import Foundation
import AVFoundation
import Observation

// MARK: - Word Lists by Grade

let spelloWords: [Int: [String]] = [
    1: ["cat","dog","hat","run","sun","map","bed","cup","log","pen",
        "bat","hop","sit","big","fun","red","hot","wet","top","got",
        "bit","cut","fit","hit","hug","jug","kid","lip","mix","nap",
        "oak","pit","rat","sad","tan","vet","wax","yak","zip","ant"],
    2: ["book","cake","home","time","help","milk","fish","frog","jump","play",
        "snow","tree","ship","boat","farm","rain","king","ball","bird","clap",
        "drop","flag","glad","grab","plan","skip","slam","spin","trip","twin",
        "clay","flip","flaw","frog","grip","plot","slot","snap","sled","strap"],
    3: ["apple","brush","catch","dance","eight","flame","grape","house","juice","knife",
        "light","magic","night","ocean","plant","queen","river","stone","table","under",
        "voice","watch","extra","young","zebra","about","bring","carry","daily","every",
        "found","going","happy","ideas","joker","keeps","least","money","never","often"],
    4: ["balloon","captain","diamond","example","factory","garbage","history","journey","kitchen","lantern",
        "message","nothing","opinion","package","quarter","rainbow","shelter","trumpet","village","warrior",
        "ancient","balance","central","correct","develop","element","fiction","grammar","harmony","inspect"],
    5: ["adventure","beautiful","celebrate","determine","education","friendship","guarantee","helicopter","important","knowledge",
        "literature","mathematics","navigation","operation","particular","qualified","recreation","scientific","technology","understand",
         "accomplish","appreciate","community","difference","encourage","fortunate","government","incredible","journalist","knowledge"],
]

// MARK: - Engine

enum SpelloMode: String, CaseIterable {
    case quiz = "Multiple Choice"
    case fill = "Type It"
    case listen = "Listen & Spell"
}

struct SpelloQuestion {
    let word: String
    let choices: [String]   // for quiz mode
}

@Observable
@MainActor
final class SpelloEngine {
    var currentQuestion: SpelloQuestion?
    var score: Int = 0
    var total: Int = 0
    var questionIndex: Int = 0
    var isCorrect: Bool? = nil
    var isFinished: Bool = false
    var mode: SpelloMode = .quiz
    var gradeLevel: Int = 1
    var userInput: String = ""

    private var questions: [SpelloQuestion] = []
    private let synth = AVSpeechSynthesizer()

    func startSession(mode: SpelloMode, gradeLevel: Int, count: Int = 10) {
        self.mode = mode
        self.gradeLevel = gradeLevel
        score = 0
        total = count
        questionIndex = 0
        isCorrect = nil
        isFinished = false
        userInput = ""

        let pool = spelloWords[gradeLevel] ?? spelloWords[1]!
        let selected = Array(pool.shuffled().prefix(count))

        questions = selected.map { word in
            var choicePool = pool.filter { $0 != word }.shuffled().prefix(3)
            var choices = (Array(choicePool) + [word]).shuffled()
            return SpelloQuestion(word: word, choices: choices)
        }
        loadQuestion()
    }

    func loadQuestion() {
        guard questionIndex < questions.count else { isFinished = true; return }
        currentQuestion = questions[questionIndex]
        isCorrect = nil
        userInput = ""
        if mode == .listen { speak(currentQuestion!.word, rate: 0.45) }
    }

    func submitChoice(_ choice: String) {
        guard let q = currentQuestion, isCorrect == nil else { return }
        let correct = choice.lowercased() == q.word.lowercased()
        isCorrect = correct
        if correct { score += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            self.questionIndex += 1
            self.loadQuestion()
        }
    }

    func submitTyped() {
        guard let q = currentQuestion, isCorrect == nil else { return }
        let correct = userInput.lowercased().trimmingCharacters(in: .whitespaces) == q.word.lowercased()
        isCorrect = correct
        if correct { score += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            self.questionIndex += 1
            self.loadQuestion()
        }
    }

    func repeatWord(rate: Float = 0.45) {
        guard let q = currentQuestion else { return }
        speak(q.word, rate: rate)
    }

    private func speak(_ word: String, rate: Float) {
        synth.stopSpeaking(at: .immediate)
        let utt = AVSpeechUtterance(string: word)
        utt.rate = rate
        utt.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utt)
    }

    var accuracy: Double { total == 0 ? 0 : Double(score) / Double(total) }
}
