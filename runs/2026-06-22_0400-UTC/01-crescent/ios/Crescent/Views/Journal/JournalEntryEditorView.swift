import SwiftUI
import SwiftData

struct JournalEntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [CrescentSettings]

    var existingEntry: MoonJournalEntry?

    @State private var content = ""
    @State private var moodRating = 3
    @State private var isSaving = false

    private var currentPhase: MoonPhase { MoonEngine.moonPhase() }
    private var currentIllum: Double   { MoonEngine.illumination() }

    var body: some View {
        NavigationStack {
            ZStack {
                CrescentTheme.navy.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    phaseHeader
                    moodSection
                    TextEditor(text: $content)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(CrescentTheme.pearl)
                        .font(.system(.body, design: .serif))
                        .frame(maxHeight: .infinity)
                        .padding()
                        .background(CrescentTheme.cardBg)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(existingEntry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(CrescentTheme.silver)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(CrescentTheme.gold)
                        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            if let e = existingEntry {
                content    = e.content
                moodRating = e.moodRating
            }
        }
    }

    private var phaseHeader: some View {
        HStack {
            Text(currentPhase.symbol)
                .font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text(currentPhase.rawValue)
                    .font(.headline)
                    .foregroundColor(CrescentTheme.pearl)
                Text(currentPhase.energy)
                    .font(.caption)
                    .foregroundColor(CrescentTheme.gold)
            }
            Spacer()
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood")
                .font(.caption)
                .tracking(1.5)
                .foregroundColor(CrescentTheme.gold)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    Button(action: { moodRating = i }) {
                        Text(i <= moodRating ? "★" : "☆")
                            .font(.title2)
                            .foregroundColor(i <= moodRating ? CrescentTheme.gold : CrescentTheme.silver)
                    }
                }
            }
        }
    }

    private func save() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        if let entry = existingEntry {
            entry.content    = trimmed
            entry.moodRating = moodRating
        } else {
            let entry = MoonJournalEntry(
                content: trimmed,
                moodRating: moodRating,
                moonPhaseRaw: currentPhase.rawValue,
                illumination: currentIllum
            )
            context.insert(entry)
        }
        if settings.first?.hapticsEnabled == true {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        }
        dismiss()
    }
}
