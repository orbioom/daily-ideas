import SwiftUI
import SwiftData

struct RitualDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [CrescentSettings]

    let ritual: RitualTemplate
    let isCompleted: Bool

    @State private var notes = ""
    @State private var checkedSteps: Set<Int> = []
    @State private var showingSaved = false

    var body: some View {
        NavigationStack {
            ZStack {
                CrescentTheme.navy.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        stepsSection
                        notesSection
                        if !isCompleted { completeButton }
                    }
                    .padding()
                }
            }
            .navigationTitle(ritual.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(CrescentTheme.silver)
                }
            }
            .overlay(
                savedOverlay,
                alignment: .bottom
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ritual.phase.symbol + " " + ritual.phase.rawValue)
                .font(.caption)
                .tracking(1.5)
                .foregroundColor(CrescentTheme.gold)
            Text(ritual.description)
                .font(.body)
                .foregroundColor(CrescentTheme.silver)
            Label(ritual.duration, systemImage: "clock")
                .font(.caption)
                .foregroundColor(CrescentTheme.silver)
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps")
                .font(.caption)
                .tracking(1.5)
                .foregroundColor(CrescentTheme.gold)
            ForEach(Array(ritual.steps.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 12) {
                    Button(action: { toggleStep(idx) }) {
                        Image(systemName: checkedSteps.contains(idx) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(checkedSteps.contains(idx) ? CrescentTheme.gold : CrescentTheme.silver)
                    }
                    Text(step)
                        .font(.body)
                        .foregroundColor(checkedSteps.contains(idx) ? CrescentTheme.silver : CrescentTheme.pearl)
                        .strikethrough(checkedSteps.contains(idx), color: CrescentTheme.silver)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.caption)
                .tracking(1.5)
                .foregroundColor(CrescentTheme.gold)
            TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .foregroundColor(CrescentTheme.pearl)
                .frame(height: 100)
                .padding(8)
                .background(CrescentTheme.cardBg)
                .cornerRadius(10)
        }
    }

    private var completeButton: some View {
        Button(action: complete) {
            Label("Mark as Complete", systemImage: "moon.stars.fill")
                .font(.headline)
                .foregroundColor(CrescentTheme.navy)
                .frame(maxWidth: .infinity)
                .padding()
                .background(CrescentTheme.gold)
                .cornerRadius(14)
        }
    }

    @ViewBuilder
    private var savedOverlay: some View {
        if showingSaved {
            Text("Ritual Complete ✨")
                .font(.headline)
                .foregroundColor(CrescentTheme.navy)
                .padding()
                .background(CrescentTheme.gold)
                .cornerRadius(12)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func toggleStep(_ idx: Int) {
        if checkedSteps.contains(idx) { checkedSteps.remove(idx) }
        else { checkedSteps.insert(idx) }
    }

    private func complete() {
        let c = RitualCompletion(
            templateId: ritual.id,
            notes: notes,
            moonPhaseRaw: MoonEngine.moonPhase().rawValue
        )
        context.insert(c)
        if settings.first?.hapticsEnabled == true {
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
        withAnimation { showingSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
    }
}
