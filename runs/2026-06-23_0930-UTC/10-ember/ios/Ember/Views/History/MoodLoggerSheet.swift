import SwiftUI
import SwiftData

/// Sheet to record a standalone mood entry with an optional note.
struct MoodLoggerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var score = 3
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Text("How are you feeling?")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, Theme.Spacing.md)

                    Text(Mood.emoji(score))
                        .font(.system(size: 64))
                        .accessibilityHidden(true)

                    MoodPicker(selection: $score, reduceMotion: reduceMotion)
                        .padding(.horizontal, Theme.Spacing.md)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note (optional)").font(.caption).foregroundStyle(Theme.textSecondary)
                        TextField("What's on your mind?", text: $note, axis: .vertical)
                            .lineLimit(1...4)
                            .padding(10)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .emberScreenBackground()
            .navigationTitle("Log Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let entry = MoodEntry(score: score,
                              note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(entry)
        try? context.save()
        Haptics.shared.success()
        dismiss()
    }
}

#Preview {
    MoodLoggerSheet()
        .previewModelContainer()
}
