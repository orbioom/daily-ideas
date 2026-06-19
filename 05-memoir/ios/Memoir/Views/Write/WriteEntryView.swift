import SwiftUI
import SwiftData

struct WriteEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var promptText: String = ""
    var existingEntry: StoryEntry? = nil

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var selectedEra: LifeEra = MemoirSettings.defaultEra
    @State private var selectedMood: EntryMood = .reflective
    @State private var showDiscardAlert = false

    private var wordCount: Int {
        let t = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? 0 : t.split(separator: " ").count
    }

    private var isDirty: Bool {
        if let existing = existingEntry {
            return title != existing.title
                || bodyText != existing.bodyText
                || selectedEra != existing.era
                || selectedMood != existing.mood
        }
        return !title.isEmpty || !bodyText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Optional prompt display
                    if !promptText.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Rectangle()
                                .fill(MemoirTheme.warmAmber)
                                .frame(width: 3)
                                .cornerRadius(2)

                            Text(promptText)
                                .font(.system(.subheadline, design: .serif).italic())
                                .foregroundColor(MemoirTheme.inkBrown.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }

                    // Title field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Give this memory a title…", text: $title)
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundColor(MemoirTheme.inkBrown)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                            )
                    }
                    .padding(.horizontal, 16)

                    // Body editor
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Story")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 3, y: 1)

                            TextEditor(text: $bodyText)
                                .font(.system(.body, design: .serif))
                                .foregroundColor(MemoirTheme.inkBrown)
                                .frame(minHeight: 220, maxHeight: .infinity)
                                .padding(12)

                            if bodyText.isEmpty {
                                Text("Write freely…")
                                    .font(.system(.body, design: .serif))
                                    .foregroundColor(.secondary.opacity(0.45))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Era Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Life Era")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(LifeEra.allCases, id: \.self) { era in
                                    EraChipSmall(era: era, isSelected: selectedEra == era) {
                                        selectedEra = era
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Mood Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(EntryMood.allCases, id: \.self) { mood in
                                    MoodChip(mood: mood, isSelected: selectedMood == mood) {
                                        selectedMood = mood
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .padding(.top, 12)
            }
            .background(MemoirTheme.parchment.opacity(0.3).ignoresSafeArea())
            .navigationTitle(existingEntry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if isDirty {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Text("\(wordCount) words")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .disabled(bodyText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Writing", role: .cancel) {}
            } message: {
                Text("Your unsaved writing will be lost.")
            }
            .onAppear {
                if let entry = existingEntry {
                    title = entry.title
                    bodyText = entry.bodyText
                    selectedEra = entry.era
                    selectedMood = entry.mood
                }
            }
        }
    }

    private func saveEntry() {
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return }

        let entryTitle = title.trimmingCharacters(in: .whitespaces).isEmpty
            ? String(trimmedBody.prefix(60))
            : title.trimmingCharacters(in: .whitespaces)

        if let existing = existingEntry {
            existing.title = entryTitle
            existing.bodyText = trimmedBody
            existing.era = selectedEra
            existing.mood = selectedMood
            existing.modifiedDate = Date()
        } else {
            let entry = StoryEntry(
                title: entryTitle,
                bodyText: trimmedBody,
                promptText: promptText,
                era: selectedEra,
                mood: selectedMood
            )
            modelContext.insert(entry)
        }

        try? modelContext.save()

        if MemoirSettings.hapticFeedback {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        dismiss()
    }
}

// MARK: - Sub-components

private struct EraChipSmall: View {
    let era: LifeEra
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(era.displayName)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected
                        ? MemoirTheme.eraColor(era)
                        : MemoirTheme.eraColor(era).opacity(0.12)
                )
                .foregroundColor(isSelected ? .white : MemoirTheme.eraColor(era))
                .clipShape(Capsule())
        }
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

private struct MoodChip: View {
    let mood: EntryMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(mood.emoji)
                    .font(.subheadline)
                Text(mood.displayName)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? MemoirTheme.moodColor(mood) : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? MemoirTheme.moodColor(mood).opacity(0.15) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? MemoirTheme.moodColor(mood) : Color(.systemGray5), lineWidth: 1)
                    )
            )
        }
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}
