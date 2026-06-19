import SwiftUI
import SwiftData

struct WriteView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WritingPrompt.eraRaw) private var prompts: [WritingPrompt]
    @Query(sort: \StoryEntry.createdDate, order: .reverse) private var entries: [StoryEntry]

    @State private var engine = MemoirEngine()
    @State private var bodyText = ""
    @State private var selectedEra: LifeEra = MemoirSettings.defaultEra
    @State private var selectedMood: EntryMood = .reflective
    @State private var showFreeWrite = false
    @State private var showSavedToast = false
    @State private var autoSaveTask: Task<Void, Never>?

    private var currentPrompt: WritingPrompt? {
        engine.todayPrompt(from: prompts)
    }

    private var wordCount: Int {
        let t = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? 0 : t.split(separator: " ").count
    }

    private var wordGoal: Int { MemoirSettings.wordGoal }

    private var goalReached: Bool { wordCount >= wordGoal }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Prompt Card
                    if let prompt = currentPrompt {
                        PromptCard(
                            prompt: prompt,
                            onSkip: { skipPrompt(prompt) }
                        )
                    } else {
                        EmptyPromptCard()
                    }

                    // Writing area
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

                            TextEditor(text: $bodyText)
                                .font(.system(.body, design: .serif))
                                .foregroundColor(MemoirTheme.inkBrown)
                                .frame(minHeight: 160)
                                .padding(12)
                                .onChange(of: bodyText) { _, _ in
                                    scheduleAutoSave()
                                }

                            if bodyText.isEmpty {
                                Text("Begin writing here…")
                                    .font(.system(.body, design: .serif))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }

                        // Word count
                        HStack {
                            Image(systemName: goalReached ? "checkmark.circle.fill" : "text.word.spacing")
                                .foregroundColor(goalReached ? .green : .secondary)
                                .animation(.spring(duration: 0.4), value: goalReached)

                            Text("\(wordCount) / \(wordGoal) words")
                                .font(.caption)
                                .foregroundColor(goalReached ? .green : .secondary)
                                .animation(.easeInOut, value: goalReached)

                            Spacer()

                            if showSavedToast {
                                Label("Saved!", systemImage: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(MemoirTheme.forestGreen)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 16)

                    // Era Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Life Era")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(LifeEra.allCases, id: \.self) { era in
                                    EraChip(era: era, isSelected: selectedEra == era) {
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
                        Text("How does this memory feel?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(EntryMood.allCases, id: \.self) { mood in
                                    MoodButton(mood: mood, isSelected: selectedMood == mood) {
                                        selectedMood = mood
                                        if MemoirSettings.hapticFeedback {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Action Buttons
                    HStack(spacing: 12) {
                        Button {
                            showFreeWrite = true
                        } label: {
                            Label("Free Write", systemImage: "pencil")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(MemoirTheme.parchment)
                                .foregroundColor(MemoirTheme.inkBrown)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(MemoirTheme.warmAmber.opacity(0.4), lineWidth: 1)
                                )
                        }

                        Button {
                            saveEntry()
                        } label: {
                            Label("Save Story", systemImage: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(bodyText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? MemoirTheme.warmAmber.opacity(0.4)
                                    : MemoirTheme.warmAmber)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(bodyText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .background(MemoirTheme.parchment.opacity(0.3).ignoresSafeArea())
            .navigationTitle("Write")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showFreeWrite) {
                WriteEntryView(promptText: "")
            }
        }
    }

    // MARK: - Actions

    private func skipPrompt(_ prompt: WritingPrompt) {
        prompt.isUsed = true
        prompt.usedDate = Date()
        try? modelContext.save()
    }

    private func saveEntry() {
        guard let prompt = currentPrompt else {
            saveEntry(withPrompt: "")
            return
        }
        saveEntry(withPrompt: prompt.promptText)
        prompt.isUsed = true
        prompt.usedDate = Date()
        try? modelContext.save()
    }

    private func saveEntry(withPrompt promptText: String) {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let title = String(trimmed.prefix(60)).trimmingCharacters(in: .whitespaces)
        let entry = StoryEntry(
            title: title,
            bodyText: trimmed,
            promptText: promptText,
            era: selectedEra,
            mood: selectedMood
        )
        modelContext.insert(entry)
        try? modelContext.save()

        bodyText = ""
        if MemoirSettings.hapticFeedback {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        withAnimation {
            showSavedToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { showSavedToast = false }
        }
    }

    private func scheduleAutoSave() {
        guard MemoirSettings.autoSave else { return }
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !Task.isCancelled else { return }
            // Auto-save only drafts the intent; saving on explicit button press
        }
    }
}

// MARK: - PromptCard

private struct PromptCard: View {
    let prompt: WritingPrompt
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(prompt.era.displayName, systemImage: "clock.arrow.circlepath")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(MemoirTheme.eraColor(prompt.era).opacity(0.2))
                    .foregroundColor(MemoirTheme.eraColor(prompt.era))
                    .clipShape(Capsule())

                Spacer()

                Button(action: onSkip) {
                    Text("Skip")
                        .font(.caption.weight(.medium))
                        .foregroundColor(MemoirTheme.warmAmber)
                }
            }

            Text(prompt.promptText)
                .font(.system(.title3, design: .serif).weight(.medium))
                .foregroundColor(MemoirTheme.inkBrown)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(MemoirTheme.warmAmber.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(MemoirTheme.warmAmber.opacity(0.35), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

private struct EmptyPromptCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(MemoirTheme.warmAmber)
            Text("All prompts completed!")
                .font(.headline)
                .foregroundColor(MemoirTheme.inkBrown)
            Text("Feel free to write anything on your mind.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(MemoirTheme.warmAmber.opacity(0.08))
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - EraChip

private struct EraChip: View {
    let era: LifeEra
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(era.displayName)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
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

// MARK: - MoodButton

private struct MoodButton: View {
    let mood: EntryMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title2)
                Text(mood.displayName)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? MemoirTheme.moodColor(mood) : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? MemoirTheme.moodColor(mood).opacity(0.15) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? MemoirTheme.moodColor(mood) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}
