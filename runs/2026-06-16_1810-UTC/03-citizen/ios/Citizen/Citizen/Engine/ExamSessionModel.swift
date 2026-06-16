import Foundation
import SwiftData

/// Drives a single graded exam session: builds items, tracks answers, computes
/// the result, and persists stats + an ExamResult.
@MainActor
@Observable
final class ExamSessionModel {
    enum Phase: Equatable {
        case loading
        case running
        case finished
        case failedToBuild(String)
    }

    let mode: ExamMode
    let category: CivicsCategory?

    private(set) var phase: Phase = .loading
    private(set) var items: [ExamItem] = []
    private(set) var answers: [ExamAnswer] = []
    private(set) var currentIndex: Int = 0
    private(set) var startDate: Date = Date()
    private(set) var elapsed: Int = 0
    private(set) var savedResult: ExamResult?

    private var timerTask: Task<Void, Never>?

    init(mode: ExamMode, category: CivicsCategory?) {
        self.mode = mode
        self.category = category
    }

    deinit {
        timerTask?.cancel()
    }

    var current: ExamItem? {
        guard currentIndex >= 0, currentIndex < items.count else { return nil }
        return items[currentIndex]
    }

    var currentAnswer: ExamAnswer? {
        guard currentIndex >= 0, currentIndex < answers.count else { return nil }
        return answers[currentIndex]
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(items.count)
    }

    var isLastItem: Bool { currentIndex >= items.count - 1 }

    // MARK: - Build

    func start(stats: [Int: QuestionStat]) async {
        phase = .loading
        // Simulate a brief async build so the loading state is real & cancellable.
        try? await Task.sleep(nanoseconds: 250_000_000)

        var rng: RandomNumberGenerator = SystemRandomNumberGenerator()
        do {
            let built = try ExamEngine.buildItems(mode: mode, category: category, stats: stats, rng: &rng)
            guard !built.isEmpty else {
                phase = .failedToBuild("There are no questions available for this mode right now.")
                return
            }
            items = built
            answers = Array(repeating: ExamAnswer(), count: built.count)
            currentIndex = 0
            startDate = Date()
            elapsed = 0
            phase = .running
            startTimer()
        } catch let error as ExamEngine.BuildError {
            phase = .failedToBuild(error.localizedDescription)
        } catch {
            phase = .failedToBuild("Couldn\u{2019}t start this session. Please try again.")
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { return }
                if self.phase == .running {
                    self.elapsed += 1
                }
            }
        }
    }

    // MARK: - Answering

    func selectChoice(_ index: Int) {
        guard phase == .running, currentIndex < answers.count else { return }
        answers[currentIndex].selectedIndex = index
    }

    func setSelfCheck(knewIt: Bool) {
        guard phase == .running, currentIndex < answers.count else { return }
        answers[currentIndex].knewIt = knewIt
    }

    func advance() {
        guard phase == .running else { return }
        if currentIndex < items.count - 1 {
            currentIndex += 1
        }
    }

    func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    // MARK: - Scoring

    /// Whether a given item was answered correctly. Self-check items count as
    /// correct only if the user said they knew it (not auto-graded against text).
    func isCorrect(itemIndex: Int) -> Bool {
        guard itemIndex >= 0, itemIndex < items.count, itemIndex < answers.count else { return false }
        let item = items[itemIndex]
        let answer = answers[itemIndex]
        if let correct = item.correctIndex {
            return answer.selectedIndex == correct
        } else {
            return answer.knewIt == true
        }
    }

    /// Count of items the user got right.
    var score: Int {
        (0..<items.count).reduce(0) { $0 + (isCorrect(itemIndex: $1) ? 1 : 0) }
    }

    var total: Int { items.count }

    var passThreshold: Int { mode.passThreshold(total: total) }

    var didPass: Bool { score >= passThreshold }

    // MARK: - Finish

    /// Finalize: stop the timer, persist per-question stats and an ExamResult.
    func finish(context: ModelContext) {
        guard phase == .running else { return }
        timerTask?.cancel()
        phase = .finished

        let store = StatStore(context: context)
        for (i, item) in items.enumerated() {
            let correct = isCorrect(itemIndex: i)
            // For self-check (varies) items, record as "seen" without crediting
            // an auto-graded correct unless the user said they knew it.
            if item.isSelfCheck {
                let knewIt: Bool? = answers[i].knewIt == true ? true : nil
                store.recordSeen(item.question.number, correct: knewIt)
            } else {
                store.recordSeen(item.question.number, correct: correct)
            }
        }

        let result = ExamResult(
            date: Date(),
            mode: mode.rawValue,
            score: score,
            total: total,
            passed: didPass,
            durationSeconds: elapsed
        )
        context.insert(result)
        do {
            try context.save()
            savedResult = result
        } catch {
            // Save failure is non-fatal; the in-session result is still shown.
            savedResult = result
        }
    }

    var elapsedFormatted: String {
        let m = elapsed / 60
        let s = elapsed % 60
        return String(format: "%d:%02d", m, s)
    }
}
