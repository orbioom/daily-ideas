import SwiftUI
import SwiftData

/// Settings: persisted prefs, Pro, export, sample data, reset, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var sessions: [DrillSession]
    @Query private var stats: [NoteStat]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showExport = false
    @State private var showAbout = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                practiceSection
                inputSection
                feedbackSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showExport) {
                ExportView(text: ExportBuilder.build(sessions: sessions, stats: stats))
            }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset practice data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reload samples", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your session history and per-note mastery.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Clef Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .clefs } label: {
                    HStack {
                        Label("Unlock Clef Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("Free Clef trains the treble clef with naturals, up to \(Pro.freeMaxLength) notes per drill.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Clef Pro")
        }
    }

    // MARK: Practice prefs

    private var practiceSection: some View {
        Section {
            Picker(selection: Binding(
                get: { settings.defaultClefRaw },
                set: { newRaw in
                    let c = Clef(rawValue: newRaw) ?? .treble
                    if c.requiresPro && !isPro { paywallReason = .clefs }
                    else { settings.defaultClefRaw = newRaw }
                })) {
                ForEach(Clef.allCases) { c in
                    Text(c.displayName + (c.requiresPro && !isPro ? " (Pro)" : "")).tag(c.rawValue)
                }
            } label: {
                Label("Default clef", systemImage: "music.note")
            }
        } header: {
            Text("Practice")
        } footer: {
            Text("The clef pre-selected on the Practice screen.")
        }
    }

    // MARK: Input prefs

    private var inputSection: some View {
        Section {
            Picker(selection: $settings.answerStyleRaw) {
                ForEach(AnswerStyle.allCases) { s in Text(s.label).tag(s.rawValue) }
            } label: {
                Label("Answer with", systemImage: "hand.tap")
            }

            Picker(selection: $settings.noteNameStyleRaw) {
                ForEach(NoteNameStyle.allCases) { s in Text(s.label).tag(s.rawValue) }
            } label: {
                Label("Note names", systemImage: "textformat")
            }

            Toggle(isOn: $settings.showKeyLabels) {
                Label("Show labels on piano keys", systemImage: "tag")
            }

            Toggle(isOn: $settings.useFlats) {
                Label("Spell accidentals as flats", systemImage: "number")
            }
        } header: {
            Text("Answer input")
        } footer: {
            Text("Piano vs. buttons, letters vs. solfège, and how black keys are named.")
        }
    }

    // MARK: Feedback prefs

    private var feedbackSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
            Toggle(isOn: $settings.soundEnabled) {
                Label("Play the note's tone", systemImage: "speaker.wave.2")
            }
        } header: {
            Text("Feedback")
        } footer: {
            Text("A soft tone plays the answered note when sound is on.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                if isPro { showExport = true } else { paywallReason = .export }
            } label: {
                Label("Export stats as text", systemImage: "square.and.arrow.up")
            }

            Button {
                loadSamples()
            } label: {
                Label("Load sample data", systemImage: "tray.and.arrow.down")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset practice data", systemImage: "trash")
            }

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your data")
        } footer: {
            Text("Everything lives on this device. Nothing is uploaded.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Clef", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func loadSamples() {
        SeedData.forceSeed(context: context)
        didSeed = true
        statusMessage = "Sample data loaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func resetAndReseed() {
        SeedData.clearAll(context: context)
        SeedData.forceSeed(context: context)
        didSeed = true
        statusMessage = "Sample data restored."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        didSeed = true
        statusMessage = "All data erased."
        Haptics.success(settings.hapticsEnabled)
    }
}
