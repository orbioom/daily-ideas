import SwiftUI
import SwiftData

/// Settings: persisted preferences (haptics, auto-speak, pronunciation, speech
/// rate, daily new limit) plus data management and an About section.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]
    @Query private var decks: [Deck]
    @AppStorage("voyage.hasOnboarded") private var hasOnboarded = false

    @State private var showResetConfirm = false
    @State private var showResetDone = false

    private var settings: AppSettings {
        if let s = settingsList.first { return s }
        let s = AppSettings()
        context.insert(s)
        try? context.save()
        return s
    }

    var body: some View {
        NavigationStack {
            Form {
                reviewSection
                pronunciationSection
                feedbackSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all progress?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset Progress", role: .destructive, action: resetProgress)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears review history and due dates for every phrase. Your decks, phrases and favorites are kept.")
            }
            .alert("Progress reset", isPresented: $showResetDone) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("All phrases are back to new. Happy studying.")
            }
        }
    }

    // MARK: Sections
    private var reviewSection: some View {
        Section {
            Stepper(value: bindingNewLimit, in: 0...50, step: 5) {
                HStack {
                    Label("New cards per session", systemImage: "sparkles")
                    Spacer()
                    Text("\(settings.dailyNewLimit)")
                        .foregroundStyle(Theme.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityValue("\(settings.dailyNewLimit) new cards per session")
        } header: {
            Text("Review")
        } footer: {
            Text("How many unseen phrases each study session introduces.")
        }
    }

    private var pronunciationSection: some View {
        Section("Pronunciation") {
            Toggle(isOn: bindingShowPron) {
                Label("Show pronunciation hints", systemImage: "character.bubble")
            }
            Toggle(isOn: bindingAutoSpeak) {
                Label("Auto-play on reveal", systemImage: "speaker.wave.2.circle")
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Speech rate", systemImage: "gauge.with.dots.needle.50percent")
                Slider(value: bindingSpeechRate, in: 0.2...0.7, step: 0.05) {
                    Text("Speech rate")
                } minimumValueLabel: {
                    Image(systemName: "tortoise.fill").foregroundStyle(Theme.textSecondary)
                } maximumValueLabel: {
                    Image(systemName: "hare.fill").foregroundStyle(Theme.textSecondary)
                }
                .accessibilityValue("\(Int(settings.speechRate * 100)) percent")
            }
        }
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle(isOn: bindingHaptics) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all progress", systemImage: "arrow.counterclockwise")
            }
            Button {
                hasOnboarded = false
            } label: {
                Label("Replay onboarding", systemImage: "sparkle.magnifyingglass")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Label("Phrases", systemImage: "text.bubble")
                Spacer()
                Text("\(decks.flatMap(\.phrases).count)").foregroundStyle(Theme.textSecondary)
            }
            HStack {
                Label("Decks", systemImage: "rectangle.stack")
                Spacer()
                Text("\(decks.count)").foregroundStyle(Theme.textSecondary)
            }
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0").foregroundStyle(Theme.textSecondary)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Voyage — travel phrases you'll actually remember. All phrases work fully offline.")
        }
    }

    // MARK: Bindings (write through to SwiftData)
    private var bindingHaptics: Binding<Bool> {
        Binding(get: { settings.hapticsEnabled }, set: { settings.hapticsEnabled = $0; save() })
    }
    private var bindingAutoSpeak: Binding<Bool> {
        Binding(get: { settings.autoSpeakOnReveal }, set: { settings.autoSpeakOnReveal = $0; save() })
    }
    private var bindingShowPron: Binding<Bool> {
        Binding(get: { settings.showPronunciation }, set: { settings.showPronunciation = $0; save() })
    }
    private var bindingSpeechRate: Binding<Double> {
        Binding(get: { settings.speechRate }, set: { settings.speechRate = $0; save() })
    }
    private var bindingNewLimit: Binding<Int> {
        Binding(get: { settings.dailyNewLimit }, set: { settings.dailyNewLimit = $0; save() })
    }

    private func save() {
        try? context.save()
    }

    private func resetProgress() {
        for phrase in decks.flatMap(\.phrases) {
            if let state = phrase.reviewState {
                context.delete(state)
                phrase.reviewState = nil
            }
        }
        try? context.save()
        showResetDone = true
    }
}

#Preview {
    if let container = PersistenceController.previewContainer() {
        SettingsView().modelContainer(container)
    }
}
