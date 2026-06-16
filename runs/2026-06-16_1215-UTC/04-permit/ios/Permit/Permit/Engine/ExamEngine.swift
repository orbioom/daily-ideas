import Foundation

/// A built, ready-to-play session of questions.
struct ExamSession: Identifiable {
    let id = UUID()
    let mode: ExamMode
    let category: QuestionCategory?
    let questions: [Question]
    let passThreshold: Double   // fraction needed to pass (e.g. 0.8)

    var requiredCorrect: Int { Int((Double(questions.count) * passThreshold).rounded(.up)) }
    var isEmpty: Bool { questions.isEmpty }
}

/// The grade of a finished session.
struct ExamGrade {
    let total: Int
    let correct: Int
    let passed: Bool
    let missedIDs: [Int]

    var percent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(correct) / Double(total) * 100).rounded())
    }
}

/// Pure, deterministic-where-possible session builder and grader. No SwiftData here.
enum ExamEngine {
    static let fullMockPassThreshold = 0.8   // 80% (e.g. 32/40)
    static let practicePassThreshold = 0.8

    // MARK: Builders

    /// Full mock: sample `length` questions spread across all categories.
    static func buildFullMock(length: Int = 40) -> ExamSession {
        let picks = sampleAcrossCategories(count: max(1, length), from: QuestionBank.all)
        return ExamSession(mode: .fullMock, category: nil, questions: picks, passThreshold: fullMockPassThreshold)
    }

    /// Quick mock: a shorter spread, default 20.
    static func buildQuickMock(length: Int = 20) -> ExamSession {
        let picks = sampleAcrossCategories(count: max(1, length), from: QuestionBank.all)
        return ExamSession(mode: .quickMock, category: nil, questions: picks, passThreshold: fullMockPassThreshold)
    }

    /// Category practice: up to `count` questions from one category.
    static func buildCategoryPractice(_ category: QuestionCategory, count: Int = 12) -> ExamSession {
        let pool = QuestionBank.questions(in: category).shuffled()
        let picks = Array(pool.prefix(max(1, count)))
        return ExamSession(mode: .practiceCategory, category: category, questions: picks, passThreshold: practicePassThreshold)
    }

    /// Review: previously missed or flagged questions.
    static func buildReview(missedIDs: [Int], flaggedIDs: [Int], limit: Int = 20) -> ExamSession {
        var ids = Array(Set(missedIDs).union(flaggedIDs))
        ids.shuffle()
        let picks = QuestionBank.questions(ids: Array(ids.prefix(max(0, limit)))).shuffled()
        return ExamSession(mode: .review, category: nil, questions: picks, passThreshold: practicePassThreshold)
    }

    /// Weak-area adaptive: weight selection toward low-accuracy and unseen questions.
    /// `accuracyByID` maps a question id to its accuracy (0–1); missing means unseen.
    static func buildWeakAreas(accuracyByID: [Int: Double], seenIDs: Set<Int>, count: Int = 15) -> ExamSession {
        // Weight: unseen questions get the highest weight, then lower-accuracy ones.
        let weighted: [(Question, Double)] = QuestionBank.all.map { q in
            if !seenIDs.contains(q.id) {
                return (q, 3.0) // unseen — prioritize
            }
            let acc = accuracyByID[q.id] ?? 0
            // Lower accuracy => higher weight, in range ~[1, 2.5].
            let weight = 1.0 + (1.0 - max(0, min(1, acc))) * 1.5
            return (q, weight)
        }
        let picks = weightedSample(weighted, count: max(1, count))
        return ExamSession(mode: .practiceCategory, category: nil, questions: picks, passThreshold: practicePassThreshold)
    }

    // MARK: Grading

    /// Grade a session given the chosen answer index for each question id.
    /// A missing or out-of-range answer counts as incorrect.
    static func grade(session: ExamSession, answers: [Int: Int]) -> ExamGrade {
        var correct = 0
        var missed: [Int] = []
        for q in session.questions {
            if let chosen = answers[q.id], chosen == q.correctIndex {
                correct += 1
            } else {
                missed.append(q.id)
            }
        }
        let total = session.questions.count
        let passed = total > 0 && correct >= session.requiredCorrect
        return ExamGrade(total: total, correct: correct, passed: passed, missedIDs: missed)
    }

    // MARK: Sampling helpers

    /// Spread `count` picks as evenly as possible across categories, then top up.
    private static func sampleAcrossCategories(count: Int, from pool: [Question]) -> [Question] {
        guard count > 0 else { return [] }
        let byCategory = Dictionary(grouping: pool, by: { $0.category })
        let categories = QuestionCategory.allCases.filter { (byCategory[$0]?.isEmpty == false) }
        guard !categories.isEmpty else { return Array(pool.shuffled().prefix(count)) }

        var result: [Question] = []
        var buckets: [QuestionCategory: [Question]] = [:]
        for c in categories { buckets[c] = (byCategory[c] ?? []).shuffled() }

        // Round-robin draw until we have enough or run out.
        var madeProgress = true
        while result.count < count && madeProgress {
            madeProgress = false
            for c in categories {
                if result.count >= count { break }
                if var bucket = buckets[c], !bucket.isEmpty {
                    result.append(bucket.removeFirst())
                    buckets[c] = bucket
                    madeProgress = true
                }
            }
        }
        return Array(result.prefix(count))
    }

    /// Sample without replacement using positive weights.
    private static func weightedSample(_ items: [(Question, Double)], count: Int) -> [Question] {
        guard count > 0 else { return [] }
        var pool = items.filter { $0.1 > 0 }
        var result: [Question] = []
        while result.count < count && !pool.isEmpty {
            let totalWeight = pool.reduce(0.0) { $0 + $1.1 }
            guard totalWeight > 0 else { break }
            let r = Double.random(in: 0..<totalWeight)
            var acc = 0.0
            var chosenIndex = 0
            for (i, entry) in pool.enumerated() {
                acc += entry.1
                if r < acc { chosenIndex = i; break }
            }
            guard pool.indices.contains(chosenIndex) else { break }
            result.append(pool[chosenIndex].0)
            pool.remove(at: chosenIndex)
        }
        return result
    }
}
