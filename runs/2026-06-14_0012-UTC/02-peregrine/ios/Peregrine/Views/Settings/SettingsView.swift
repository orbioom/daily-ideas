import SwiftUI
import SwiftData

/// Settings: quiz defaults, timer, haptics, Pro/restore, reset, about.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("isPro") private var isPro = false
    @AppStorage("defaultMode") private var defaultModeRaw = QuizMode.flagToCountry.rawValue
    @AppStorage("defaultLength") private var defaultLength = 10
    @AppStorage("timerEnabled") private var timerEnabled = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @State private var showPaywall = false
    @State private var showResetConfirm = false
    @State private var showResetDone = false

    private var defaultMode: QuizMode {
        QuizMode(rawValue: defaultModeRaw) ?? .flagToCountry
    }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                quizSection
                feedbackSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Reset all progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { performReset() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently erases your mastery, stars and quiz history. This cannot be undone.")
            }
            .alert("Progress reset", isPresented: $showResetDone) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your atlas is fresh again.")
            }
        }
    }

    // MARK: Sections

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Peregrine Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Active")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Peregrine Pro", systemImage: "star.fill")
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        Text("$4.99")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        } footer: {
            Text(isPro ? "All continents, modes and unlimited quizzes are unlocked."
                       : "One-time purchase. All continents, all modes, unlimited quizzes and full stats.")
        }
        .listRowBackground(Theme.surface)
    }

    private var quizSection: some View {
        Section("Quiz defaults") {
            Picker("Default length", selection: $defaultLength) {
                ForEach([10, 20, 30], id: \.self) { Text("\($0) questions").tag($0) }
            }
            Picker("Default mode", selection: $defaultModeRaw) {
                ForEach(QuizMode.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            Toggle("Show timer", isOn: $timerEnabled)
                .tint(Theme.accent)
        }
        .listRowBackground(Theme.surface)
    }

    private var feedbackSection: some View {
        Section {
            Toggle("Haptics", isOn: $hapticsEnabled)
                .tint(Theme.accent)
        } header: {
            Text("Feedback")
        } footer: {
            Text("Subtle vibrations on correct and incorrect answers. Peregrine plays no audio.")
        }
        .listRowBackground(Theme.surface)
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all progress", systemImage: "trash")
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Countries")
                Spacer()
                Text("\(CountryData.all.count)").foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Peregrine — a calm, ad-free world-geography trainer. Made for curious explorers.")
        }
        .listRowBackground(Theme.surface)
    }

    private func performReset() {
        ProgressStore(context: modelContext).resetAll()
        Haptics.celebrate()
        showResetDone = true
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [CountryProgress.self, QuizSession.self], inMemory: true)
}
