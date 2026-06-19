import Foundation
import SwiftData
import SwiftUI

// MARK: - Settings Keys

enum KanaSettings {
    static let onboardingDone = "kana_onboarding_done"
    static let studyCardType = "kana_study_card_type"
    static let dailyGoal = "kana_daily_goal"
    static let showRomaji = "kana_show_romaji"
    static let hapticFeedback = "kana_haptic_feedback"
}

// MARK: - KanaEngine

@Observable
final class KanaEngine {
    var studyQueue: [KanaCard] = []
    var currentCard: KanaCard?
    var showAnswer: Bool = false
    var sessionCorrect: Int = 0
    var sessionIncorrect: Int = 0
    var sessionStart: Date = Date.now
    var isSessionComplete: Bool = false

    private var sessionCardType: CardType = .hiragana

    func loadQueue(from cards: [KanaCard], type: CardType?) {
        let filtered: [KanaCard]
        if let type = type {
            filtered = cards.filter { $0.cardType == type && $0.isDue }
        } else {
            filtered = cards.filter { $0.isDue }
        }

        let shuffled = filtered.shuffled()
        studyQueue = Array(shuffled.prefix(20))
        sessionCorrect = 0
        sessionIncorrect = 0
        sessionStart = Date.now
        isSessionComplete = false
        showAnswer = false

        if let type = type {
            sessionCardType = type
        } else {
            sessionCardType = .hiragana
        }

        currentCard = studyQueue.first
    }

    func answer(correct: Bool, card: KanaCard, context: ModelContext) {
        card.review(correct: correct)

        if correct {
            sessionCorrect += 1
        } else {
            sessionIncorrect += 1
        }

        try? context.save()

        if let idx = studyQueue.firstIndex(where: { $0.id == card.id }) {
            studyQueue.remove(at: idx)
        }

        showAnswer = false

        if studyQueue.isEmpty {
            isSessionComplete = true
            currentCard = nil
            saveSession(context: context)
        } else {
            currentCard = studyQueue.first
        }
    }

    func nextCard() {
        guard !studyQueue.isEmpty else {
            currentCard = nil
            isSessionComplete = true
            return
        }
        currentCard = studyQueue.first
        showAnswer = false
    }

    private func saveSession(context: ModelContext) {
        let total = sessionCorrect + sessionIncorrect
        guard total > 0 else { return }

        let duration = Int(Date.now.timeIntervalSince(sessionStart))
        let session = StudySession(
            cardType: sessionCardType,
            cardsReviewed: total,
            correctCount: sessionCorrect,
            durationSeconds: duration
        )
        context.insert(session)
        try? context.save()
    }

    // MARK: - Stats Helpers

    func totalLearned(_ cards: [KanaCard]) -> Int {
        cards.filter { $0.isLearned }.count
    }

    func accuracy(_ cards: [KanaCard]) -> Double {
        let reviewed = cards.filter { $0.totalReviews > 0 }
        guard !reviewed.isEmpty else { return 0.0 }
        let totalCorrect = reviewed.reduce(0) { $0 + $1.correctReviews }
        let totalReviews = reviewed.reduce(0) { $0 + $1.totalReviews }
        guard totalReviews > 0 else { return 0.0 }
        return Double(totalCorrect) / Double(totalReviews)
    }

    func streakDays(_ sessions: [StudySession]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var checkDay = today

        while uniqueDays.contains(checkDay) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = previousDay
        }

        return streak
    }

    func cardsDueToday(_ cards: [KanaCard]) -> Int {
        cards.filter { $0.isDue }.count
    }

    func weeklyReviews(_ sessions: [StudySession]) -> [(day: String, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var result: [(day: String, count: Int)] = []

        for i in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayLabel = formatter.string(from: day)
            let count = sessions.filter {
                calendar.startOfDay(for: $0.date) == day
            }.reduce(0) { $0 + $1.cardsReviewed }
            result.append((day: dayLabel, count: count))
        }

        return result
    }

    func accuracyByType(_ cards: [KanaCard], type: CardType) -> Double {
        let typeCards = cards.filter { $0.cardType == type && $0.totalReviews > 0 }
        guard !typeCards.isEmpty else { return 0.0 }
        let totalCorrect = typeCards.reduce(0) { $0 + $1.correctReviews }
        let totalReviews = typeCards.reduce(0) { $0 + $1.totalReviews }
        guard totalReviews > 0 else { return 0.0 }
        return Double(totalCorrect) / Double(totalReviews)
    }

    func masteryPercent(_ cards: [KanaCard], type: CardType) -> Double {
        let typeCards = cards.filter { $0.cardType == type }
        guard !typeCards.isEmpty else { return 0.0 }
        let learned = typeCards.filter { $0.isLearned }.count
        return Double(learned) / Double(typeCards.count)
    }

    func todayAccuracy(_ sessions: [StudySession]) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let todaySessions = sessions.filter { calendar.startOfDay(for: $0.date) == today }
        let totalReviewed = todaySessions.reduce(0) { $0 + $1.cardsReviewed }
        let totalCorrect = todaySessions.reduce(0) { $0 + $1.correctCount }
        guard totalReviewed > 0 else { return 0.0 }
        return Double(totalCorrect) / Double(totalReviewed)
    }
}

// MARK: - Seed Data

func seedDefaultCards(context: ModelContext) {
    let descriptor = FetchDescriptor<KanaCard>()
    let count = (try? context.fetchCount(descriptor)) ?? 0
    guard count == 0 else { return }

    // Hiragana
    let hiragana: [(String, String)] = [
        ("あ", "a"), ("い", "i"), ("う", "u"), ("え", "e"), ("お", "o"),
        ("か", "ka"), ("き", "ki"), ("く", "ku"), ("け", "ke"), ("こ", "ko"),
        ("さ", "sa"), ("し", "shi"), ("す", "su"), ("せ", "se"), ("そ", "so"),
        ("た", "ta"), ("ち", "chi"), ("つ", "tsu"), ("て", "te"), ("と", "to"),
        ("な", "na"), ("に", "ni"), ("ぬ", "nu"), ("ね", "ne"), ("の", "no"),
        ("は", "ha"), ("ひ", "hi"), ("ふ", "fu"), ("へ", "he"), ("ほ", "ho"),
        ("ま", "ma"), ("み", "mi"), ("む", "mu"), ("め", "me"), ("も", "mo"),
        ("や", "ya"), ("ゆ", "yu"), ("よ", "yo"),
        ("ら", "ra"), ("り", "ri"), ("る", "ru"), ("れ", "re"), ("ろ", "ro"),
        ("わ", "wa"), ("を", "wo"), ("ん", "n")
    ]

    for (char, rom) in hiragana {
        let card = KanaCard(character: char, romaji: rom, meaning: "", cardType: .hiragana)
        context.insert(card)
    }

    // Katakana
    let katakana: [(String, String)] = [
        ("ア", "a"), ("イ", "i"), ("ウ", "u"), ("エ", "e"), ("オ", "o"),
        ("カ", "ka"), ("キ", "ki"), ("ク", "ku"), ("ケ", "ke"), ("コ", "ko"),
        ("サ", "sa"), ("シ", "shi"), ("ス", "su"), ("セ", "se"), ("ソ", "so"),
        ("タ", "ta"), ("チ", "chi"), ("ツ", "tsu"), ("テ", "te"), ("ト", "to"),
        ("ナ", "na"), ("ニ", "ni"), ("ヌ", "nu"), ("ネ", "ne"), ("ノ", "no"),
        ("ハ", "ha"), ("ヒ", "hi"), ("フ", "fu"), ("ヘ", "he"), ("ホ", "ho"),
        ("マ", "ma"), ("ミ", "mi"), ("ム", "mu"), ("メ", "me"), ("モ", "mo"),
        ("ヤ", "ya"), ("ユ", "yu"), ("ヨ", "yo"),
        ("ラ", "ra"), ("リ", "ri"), ("ル", "ru"), ("レ", "re"), ("ロ", "ro"),
        ("ワ", "wa"), ("ヲ", "wo"), ("ン", "n")
    ]

    for (char, rom) in katakana {
        let card = KanaCard(character: char, romaji: rom, meaning: "", cardType: .katakana)
        context.insert(card)
    }

    // N5 Kanji (20)
    let kanji: [(String, String, String)] = [
        ("日", "nichi", "sun / day"),
        ("月", "tsuki", "moon / month"),
        ("火", "hi", "fire"),
        ("水", "mizu", "water"),
        ("木", "ki", "tree / wood"),
        ("金", "kin", "gold / money"),
        ("土", "tsuchi", "earth / soil"),
        ("山", "yama", "mountain"),
        ("川", "kawa", "river"),
        ("田", "ta", "rice field"),
        ("人", "hito", "person"),
        ("大", "dai", "big / large"),
        ("小", "sho", "small / little"),
        ("上", "ue", "up / above"),
        ("下", "shita", "down / below"),
        ("中", "naka", "middle / inside"),
        ("本", "hon", "book / origin"),
        ("年", "nen", "year"),
        ("今", "ima", "now / present"),
        ("何", "nani", "what")
    ]

    for (char, rom, meaning) in kanji {
        let card = KanaCard(character: char, romaji: rom, meaning: meaning, cardType: .kanji)
        context.insert(card)
    }

    try? context.save()
}
