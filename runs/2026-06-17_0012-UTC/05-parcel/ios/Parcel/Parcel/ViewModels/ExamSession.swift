import SwiftUI
import SwiftData

/// One question inside a running session, carrying its shuffled presentation order
/// and the user's selection. The canonical `Question.correctIndex` is never mutated;
/// the displayed correct index is derived from `order`.
struct SessionItem: Identifiable {
    let id: Int               // mirrors Question.id
    let question: Question
    /// Presentation order: indices into `question.options`.
    let order: [Int]
    /// The user's chosen presentation index (0...3), if answered.
    var selected: Int? = nil
    var flagged: Bool = false

    /// Options in the order they should be displayed.
    var displayedOptions: [String] {
        order.compactMap { question.options[safe: $0] }
    }

    /// The presentation index that is the correct answer.
    var correctPresentationIndex: Int {
        order.firstIndex(of: question.correctIndex) ?? 0
    }

    var isAnswered: Bool { selected != nil }

    var isCorrect: Bool {
        guard let selected else { return false }
        return selected == correctPresentationIndex
    }
}

/// Builds the question set for a given mode. Pure and deterministic given a seed.
enum SessionBuilder {

    static func build(mode: ExamMode,
                      prefs: AppPreferences,
                      topic: Topic? = nil,
                      reviewIds: [Int] = [],
                      stats: [QuestionStat] = [],
                      seed: UInt64 = UInt64(Date().timeIntervalSince1970)) -> [SessionItem] {
        var gen = SeededGenerator(seed: seed)
        let bank = QuestionBank.all
        let chosen: [Question]

        switch mode {
        case .mock:
            chosen = Array(bank.shuffled(using: &gen).prefix(clamp(prefs.mockLength, 20, bank.count)))
        case .quick:
            chosen = Array(bank.shuffled(using: &gen).prefix(clamp(prefs.quickLength, 5, bank.count)))
        case .topic:
            let pool = topic.map { QuestionBank.forTopic($0) } ?? bank
            chosen = pool.shuffled(using: &gen)
        case .review:
            let ids = Set(reviewIds)
            let pool = bank.filter { ids.contains($0.id) }
            chosen = Array(pool.shuffled(using: &gen).prefix(clamp(prefs.mockLength, 1, max(1, pool.count))))
        case .adaptive:
            chosen = weightedPick(bank: bank, stats: stats,
                                  count: clamp(20, 1, bank.count), gen: &gen)
        }

        return chosen.map { question in
            let order: [Int]
            if prefs.shuffleOptions {
                var og = SeededGenerator(seed: seed &+ UInt64(question.id) &* 2_654_435_761)
                order = Array(0..<question.options.count).shuffled(using: &og)
            } else {
                order = Array(0..<question.options.count)
            }
            return SessionItem(id: question.id, question: question, order: order)
        }
    }

    /// Weighted selection favoring low-mastery and unseen questions.
    private static func weightedPick(bank: [Question], stats: [QuestionStat],
                                     count: Int, gen: inout SeededGenerator) -> [Question] {
        let statMap = Dictionary(uniqueKeysWithValues: stats.map { ($0.questionId, $0) })
        // weight: unseen = 1.0, otherwise (1 - mastery) floored so nothing is impossible.
        var pool: [(Question, Double)] = bank.map { q in
            if let s = statMap[q.id], s.seen > 0 {
                return (q, max(0.08, 1.0 - s.mastery))
            }
            return (q, 1.0)
        }
        var result: [Question] = []
        let n = min(count, pool.count)
        for _ in 0..<n {
            let total = pool.reduce(0.0) { $0 + $1.1 }
            guard total > 0 else { break }
            let r = Double(gen.next() % 1_000_000) / 1_000_000.0 * total
            var acc = 0.0
            var pickedIndex = pool.count - 1
            for (i, entry) in pool.enumerated() {
                acc += entry.1
                if r <= acc { pickedIndex = i; break }
            }
            result.append(pool[pickedIndex].0)
            pool.remove(at: pickedIndex)
        }
        return result
    }

    private static func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int {
        guard hi >= lo else { return lo }
        return min(hi, max(lo, v))
    }
}

/// Drives a live study session: navigation, selection, flagging, timing, grading.
@MainActor
@Observable
final class ExamSession: Identifiable {
    let id = UUID()
    let mode: ExamMode
    let topic: Topic?
    let passPercent: Int
    let startDate: Date
    private(set) var items: [SessionItem]
    var index: Int = 0
    private(set) var finished: Bool = false
    private(set) var finishedDate: Date?

    init(mode: ExamMode, topic: Topic?, passPercent: Int, items: [SessionItem],
         startDate: Date = Date()) {
        self.mode = mode
        self.topic = topic
        self.passPercent = passPercent
        self.items = items
        self.startDate = startDate
    }

    /// Builds a ready-to-run session for a mode, pulling review/adaptive inputs from the store.
    static func make(mode: ExamMode, prefs: AppPreferences, topic: Topic? = nil,
                     context: ModelContext) -> ExamSession {
        let reviewIds = mode == .review ? StatStore.reviewPoolIds(in: context) : []
        let stats = mode == .adaptive ? StatStore.all(in: context) : []
        let items = SessionBuilder.build(mode: mode, prefs: prefs, topic: topic,
                                         reviewIds: reviewIds, stats: stats)
        return ExamSession(mode: mode, topic: topic, passPercent: prefs.passPercent, items: items)
    }

    var isEmpty: Bool { items.isEmpty }
    var count: Int { items.count }

    var current: SessionItem? { items[safe: index] }

    var progress: Double {
        guard count > 0 else { return 0 }
        return Double(index + 1) / Double(count)
    }

    var answeredCount: Int { items.filter { $0.isAnswered }.count }

    var correctCount: Int { items.filter { $0.isCorrect }.count }

    var scorePercent: Int {
        guard count > 0 else { return 0 }
        return Int((Double(correctCount) / Double(count) * 100).rounded())
    }

    var passed: Bool { scorePercent >= passPercent }

    var elapsedSeconds: Int {
        let end = finishedDate ?? Date()
        return max(0, Int(end.timeIntervalSince(startDate)))
    }

    var isLast: Bool { index >= count - 1 }
    var isFirst: Bool { index <= 0 }

    /// Whether all items have been answered (gates Finish for non-timed modes).
    var allAnswered: Bool { count > 0 && answeredCount == count }

    func select(_ presentationIndex: Int) {
        guard items.indices.contains(index) else { return }
        // In timed mock you can change an answer until finishing; in study modes too.
        items[index].selected = presentationIndex
    }

    func toggleFlag() {
        guard items.indices.contains(index) else { return }
        items[index].flagged.toggle()
    }

    func goNext() { if index < count - 1 { index += 1 } }
    func goPrev() { if index > 0 { index -= 1 } }
    func jump(to i: Int) { if items.indices.contains(i) { index = i } }

    func finish() {
        guard !finished else { return }
        finished = true
        finishedDate = Date()
    }
}
