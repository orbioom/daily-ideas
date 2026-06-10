import Foundation

/// A multiple-choice question used by the math / focus / logic games.
struct ChoiceQuestion {
    let prompt: String
    /// For Color Focus, the prompt is colored — this is the ink color name.
    let promptColorName: String?
    let choices: [String]
    let answerIndex: Int
}

enum QuestionGen {

    // MARK: - Quick Math
    static func math(_ difficulty: Difficulty) -> ChoiceQuestion {
        let (a, b, op): (Int, Int, String)
        switch difficulty {
        case .easy:
            op = ["+", "-", "×"].randomElement()!
            a = Int.random(in: 2...12); b = Int.random(in: 2...12)
        case .medium:
            op = ["+", "-", "×", "÷"].randomElement()!
            a = Int.random(in: 5...25); b = Int.random(in: 2...12)
        case .hard:
            op = ["+", "-", "×", "÷"].randomElement()!
            a = Int.random(in: 12...60); b = Int.random(in: 3...15)
        }

        let answer: Int
        let prompt: String
        switch op {
        case "+": answer = a + b; prompt = "\(a) + \(b)"
        case "-":
            let hi = max(a, b), lo = min(a, b)
            answer = hi - lo; prompt = "\(hi) − \(lo)"
        case "×": answer = a * b; prompt = "\(a) × \(b)"
        default: // ÷ — build a clean division
            let product = a * b
            answer = a; prompt = "\(product) ÷ \(b)"
        }

        return choiceQuestion(answer: answer, prompt: prompt,
                              spread: max(3, abs(answer) / 4 + 2))
    }

    // MARK: - Color Focus (Stroop)
    static let colorNames = ["Red", "Blue", "Green", "Orange", "Purple"]

    static func focus(_ difficulty: Difficulty) -> ChoiceQuestion {
        let palette = difficulty == .easy ? Array(colorNames.prefix(3)) : colorNames
        let wordColor = palette.randomElement()!     // the word's text
        var inkColor = palette.randomElement()!       // the actual ink
        // Bias toward mismatching ink/word to make it harder than chance.
        if difficulty != .easy && Bool.random() {
            inkColor = palette.filter { $0 != wordColor }.randomElement() ?? inkColor
        }
        // The correct answer is the INK color.
        var options = palette.shuffled()
        if options.count > 4 { options = Array(options.prefix(4)) }
        if !options.contains(inkColor) { options[0] = inkColor; options.shuffle() }
        let answerIndex = options.firstIndex(of: inkColor) ?? 0
        return ChoiceQuestion(prompt: wordColor, promptColorName: inkColor,
                              choices: options, answerIndex: answerIndex)
    }

    // MARK: - Next in Line (sequences)
    static func logic(_ difficulty: Difficulty) -> ChoiceQuestion {
        // Pick a pattern: arithmetic, geometric, or square/triangular.
        enum Kind: CaseIterable { case arithmetic, geometric, squares, fib }
        let kinds: [Kind] = difficulty == .easy ? [.arithmetic, .geometric] : Kind.allCases
        let kind = kinds.randomElement()!
        var seq: [Int] = []
        switch kind {
        case .arithmetic:
            let start = Int.random(in: 1...9)
            let step = Int.random(in: 2...(difficulty == .hard ? 9 : 5))
            seq = (0..<5).map { start + $0 * step }
        case .geometric:
            let start = Int.random(in: 1...4)
            let ratio = [2, 3].randomElement()!
            seq = (0..<5).map { start * Int(pow(Double(ratio), Double($0))) }
        case .squares:
            let offset = Int.random(in: 1...3)
            seq = (offset..<(offset + 5)).map { $0 * $0 }
        case .fib:
            var a = Int.random(in: 1...3), b = Int.random(in: 2...4)
            seq = [a, b]
            for _ in 0..<3 { let c = a + b; seq.append(c); a = b; b = c }
        }
        let answer = seq.removeLast()
        let prompt = seq.map(String.init).joined(separator: ",  ") + ",  ?"
        return choiceQuestion(answer: answer, prompt: prompt,
                              spread: max(2, abs(answer) / 5 + 1))
    }

    // MARK: - Shared distractor builder
    private static func choiceQuestion(answer: Int, prompt: String, spread: Int) -> ChoiceQuestion {
        var set = Set<Int>([answer])
        var guard0 = 0
        while set.count < 4 && guard0 < 100 {
            guard0 += 1
            let delta = Int.random(in: -spread...spread)
            let cand = answer + (delta == 0 ? spread + 1 : delta)
            if cand >= 0 { set.insert(cand) }
        }
        // Ensure four options even if collisions kept us short.
        var pad = answer + spread + 2
        while set.count < 4 { set.insert(pad); pad += 1 }
        let choices = Array(set).shuffled().map(String.init)
        let answerIndex = choices.firstIndex(of: String(answer)) ?? 0
        return ChoiceQuestion(prompt: prompt, promptColorName: nil,
                              choices: choices, answerIndex: answerIndex)
    }

    // MARK: - Word Scramble
    static func scramble(_ difficulty: Difficulty) -> (scrambled: [Character], answer: String) {
        let lengths: [Int]
        switch difficulty {
        case .easy: lengths = [4, 5]
        case .medium: lengths = [5, 6]
        case .hard: lengths = [6, 7, 8]
        }
        let len = lengths.randomElement()!
        let pool = WordBank.words(forLength: len).isEmpty
            ? WordBank.words(forLength: 5) : WordBank.words(forLength: len)
        let word = pool.randomElement() ?? "brain"
        var letters = Array(word)
        // Shuffle until different from the original (guard against trivial no-op).
        var attempts = 0
        repeat {
            letters.shuffle()
            attempts += 1
        } while String(letters) == word && attempts < 8
        return (letters, word)
    }
}
