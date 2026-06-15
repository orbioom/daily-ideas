import SwiftUI

/// Drives the test runner. Persists an in-progress draft (responses + index) to
/// @AppStorage so an interrupted test resumes exactly where it left off.
@MainActor
final class TestViewModel: ObservableObject {
    enum Phase: Equatable {
        case asking
        case computing
        case finished(ScoredResultBox)
    }

    /// Lightweight box so ScoredResult can ride in an Equatable Phase.
    struct ScoredResultBox: Equatable {
        let typeCode: String
        let result: ScoredResult
        static func == (lhs: ScoredResultBox, rhs: ScoredResultBox) -> Bool {
            lhs.typeCode == rhs.typeCode
        }
    }

    @Published var index: Int = 0
    @Published var responses: [Int: Int] = [:]
    @Published var phase: Phase = .asking

    private let items = ItemBank.ordered

    // Draft persistence keys
    private let draftResponsesKey = "draftResponses"
    private let draftIndexKey = "draftIndex"

    var total: Int { items.count }
    var currentItem: Item? { items.indices.contains(index) ? items[index] : nil }
    var progress: Double { total > 0 ? Double(responses.count) / Double(total) : 0 }
    var hasDraft: Bool { !responses.isEmpty }

    init() {
        loadDraft()
    }

    func answer(for item: Item) -> Int? { responses[item.id] }

    /// Record an answer and advance.
    func select(value: Int, for item: Item, hapticsEnabled: Bool) {
        let clamped = min(5, max(1, value))
        responses[item.id] = clamped
        Haptics.selection(enabled: hapticsEnabled)
        saveDraft()
        advance()
    }

    func advance() {
        if index < total - 1 {
            withAnimation(.easeInOut(duration: 0.2)) { index += 1 }
        }
    }

    func goBack() {
        guard index > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) { index -= 1 }
    }

    var isOnLastQuestion: Bool { index == total - 1 }
    var canFinish: Bool { ScoringEngine.isComplete(responses) }

    /// Compute the result. Shows a brief computing phase, then finishes.
    func finish(hapticsEnabled: Bool) async {
        guard canFinish else { return }
        phase = .computing
        // A brief, honest "computing" beat (also lets the reveal feel earned).
        try? await Task.sleep(nanoseconds: 900_000_000)
        let result = ScoringEngine.score(responses: responses)
        Haptics.success(enabled: hapticsEnabled)
        phase = .finished(ScoredResultBox(typeCode: result.typeCode, result: result))
    }

    /// Snapshot of the current responses for persisting into a Profile.
    var snapshotResponses: [Int: Int] { responses }

    // MARK: - Reset

    func startFresh() {
        responses = [:]
        index = 0
        phase = .asking
        clearDraft()
    }

    /// Resume an existing draft (no-op if none) — keeps current state.
    func resume() {
        phase = .asking
    }

    // MARK: - Draft persistence

    private func saveDraft() {
        let stringKeyed = Dictionary(uniqueKeysWithValues: responses.map { (String($0.key), $0.value) })
        if let data = try? JSONEncoder().encode(stringKeyed) {
            UserDefaults.standard.set(data, forKey: draftResponsesKey)
        }
        UserDefaults.standard.set(index, forKey: draftIndexKey)
    }

    private func loadDraft() {
        if let data = UserDefaults.standard.data(forKey: draftResponsesKey),
           let stringKeyed = try? JSONDecoder().decode([String: Int].self, from: data) {
            var restored: [Int: Int] = [:]
            for (k, v) in stringKeyed where Int(k) != nil {
                if let key = Int(k) { restored[key] = v }
            }
            responses = restored
        }
        let savedIndex = UserDefaults.standard.integer(forKey: draftIndexKey)
        index = min(max(0, savedIndex), max(0, total - 1))
    }

    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftResponsesKey)
        UserDefaults.standard.removeObject(forKey: draftIndexKey)
    }

    /// Static helper for Settings "reset draft".
    static func clearStoredDraft() {
        UserDefaults.standard.removeObject(forKey: "draftResponses")
        UserDefaults.standard.removeObject(forKey: "draftIndex")
    }

    static func hasStoredDraft() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: "draftResponses"),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else { return false }
        return !dict.isEmpty
    }
}
