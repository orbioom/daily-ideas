import Foundation
import SwiftData

/// Drives the guided reflection flow: stepping through prompts, choosing a
/// virtue (morning) or a mood (evening), and saving exactly one `Reflection`
/// per (day, kind) — creating a new one or updating today's existing entry.
@Observable
final class ReflectionViewModel {
    enum Phase { case writing, saving, done, failed }

    let kind: Reflection.Kind
    let promptSet: PromptSet
    /// One answer slot per prompt.
    var responses: [String]
    var virtue: Virtue
    /// Evening mood, 1...5 (0 = not yet chosen).
    var mood: Int
    var step: Int = 0
    var phase: Phase = .writing
    var errorMessage: String?

    /// The existing reflection being edited, if any.
    private let existing: Reflection?

    init(kind: Reflection.Kind, promptSet: PromptSet, existing: Reflection?) {
        self.kind = kind
        self.promptSet = promptSet
        self.existing = existing
        self.virtue = existing?.virtue ?? StoicEngine.virtueOfDay(for: .now)
        self.mood = existing?.mood ?? 0
        // Align stored responses to the prompt set length.
        var slots = Array(repeating: "", count: promptSet.prompts.count)
        if let saved = existing?.responses {
            for i in slots.indices where i < saved.count { slots[i] = saved[i] }
        }
        self.responses = slots
    }

    /// Total steps: one per prompt, plus a final review/commit step.
    var totalSteps: Int { promptSet.prompts.count + 1 }
    var isFinalStep: Bool { step >= promptSet.prompts.count }
    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(min(step, totalSteps)) / Double(totalSteps)
    }
    var isEditing: Bool { existing != nil }

    /// At least one non-empty answer is required to save.
    var canSave: Bool {
        responses.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && (kind == .morning || mood > 0)
    }

    func currentPrompt() -> String? {
        promptSet.prompts.indices.contains(step) ? promptSet.prompts[step] : nil
    }

    func binding(at index: Int) -> String {
        responses.indices.contains(index) ? responses[index] : ""
    }

    func advance() {
        if step < totalSteps - 1 {
            step += 1
            Haptics.soft()
        }
    }

    func back() {
        if step > 0 { step -= 1 }
    }

    @discardableResult
    func save(to context: ModelContext) -> Bool {
        phase = .saving
        let cleaned = responses.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let entry = existing {
            entry.responses = cleaned
            entry.virtue = virtue
            entry.mood = kind == .evening ? mood : 0
            entry.promptKey = promptSet.key
        } else {
            let entry = Reflection(
                kind: kind,
                promptKey: promptSet.key,
                responses: cleaned,
                mood: kind == .evening ? mood : 0,
                virtue: virtue)
            context.insert(entry)
        }
        do {
            try context.save()
            phase = .done
            Haptics.success()
            return true
        } catch {
            phase = .failed
            errorMessage = "Could not save your reflection. Please try again."
            Haptics.warning()
            return false
        }
    }
}
