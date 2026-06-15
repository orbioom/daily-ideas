import SwiftUI
import SwiftData

struct CheckInEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let existing: CheckIn?

    @State private var mood: Int = 3
    @State private var note: String = ""
    @State private var gratitude: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(spacing: 12) {
                        Text("How does today feel?")
                            .font(Theme.rounded(18, .semibold))
                            .foregroundStyle(Theme.ink)
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mood = value }
                                    settings.haptic(.light)
                                } label: {
                                    VStack(spacing: 6) {
                                        MoodFace(mood: value, size: mood == value ? 52 : 44, selected: mood == value)
                                        Text(MoodFace.label(value))
                                            .font(Theme.rounded(11, mood == value ? .semibold : .regular))
                                            .foregroundStyle(mood == value ? Theme.ink : Theme.inkSoft)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(MoodFace.label(value))
                                .accessibilityAddTraits(mood == value ? [.isButton, .isSelected] : .isButton)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("A note (optional)")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        TextField("What's on your mind?", text: $note, axis: .vertical)
                            .font(Theme.rounded(15))
                            .lineLimit(3...6)
                            .padding(12)
                            .card(Theme.surface)
                            .accessibilityLabel("Reflection note")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("One thing you're grateful for (optional)")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        TextField("Something small counts", text: $gratitude, axis: .vertical)
                            .font(Theme.rounded(15))
                            .lineLimit(2...4)
                            .padding(12)
                            .card(Theme.surface)
                            .accessibilityLabel("Gratitude")
                    }
                }
                .padding()
            }
            .background(Theme.bg)
            .navigationTitle(existing == nil ? "Check in" : "Edit check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let existing else { return }
        mood = existing.mood
        note = existing.note
        gratitude = existing.gratitude ?? ""
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGratitude = gratitude.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try CareStore(context: modelContext).saveCheckIn(
                mood: mood,
                note: trimmedNote,
                gratitude: trimmedGratitude.isEmpty ? nil : trimmedGratitude
            )
            settings.haptic(.success)
            dismiss()
        } catch {
            errorMessage = "Couldn't save your check-in. Please try again."
        }
    }
}
